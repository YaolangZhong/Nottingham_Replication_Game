import pandas as pd
import numpy as np
import pyreadr
import statsmodels.formula.api as smf

file_path = "/Users/yaolangzhong/Nottingham_Replication/original_code/"

# Load the mpu dataframe (RData files can be converted to csv for use with Python)
mpu = pyreadr.read_r(file_path + "data/mpu.RData")["mpu"]
mpu = mpu.rename(columns={'mpu10': 'mpu', 'f10': 'f'})
# monthly uncertainty
mpu['ym'] = mpu['date'].apply(lambda x: int(x.strftime('%Y%m')))
datam = mpu.groupby('ym').agg({'mpu': 'mean', 'f': 'mean'}).reset_index()
# quarterly uncertainty
mpu['yq'] = mpu['date'].apply(lambda x: int(x.strftime('%Y'))*10 + ((x.month - 1) // 3 + 1))
dataq = mpu.groupby('yq').agg({'mpu': 'mean', 'f': 'mean'}).reset_index()
# JLN macro uncertainty
jln = pd.read_csv("data/MacroUncertainty_JLN.csv")
jln['date'] = pd.date_range(start='1960-07-01', periods=len(jln), freq='MS')
jln['ym'] = jln['date'].apply(lambda x: int(x.strftime('%Y%m')))
jln = jln.drop(['Date'], axis=1)
jln.columns = jln.columns.str.replace('=', '_', regex=True)
# Merging
datam = datam.merge(jln, how='left', on='ym')

# real time macro uncertainty - Rogers-Xu
rtmu = pd.read_csv("data/real_time_MU_RX.csv", sep=";", decimal=",", skiprows=1, names=["date", "mu"])
rtmu['date'] = pd.to_datetime(rtmu['date'])
rtmu['ym'] = rtmu['date'].dt.year*100 + rtmu['date'].dt.month
rtmu = rtmu.drop(columns=['date'])
datam = datam.merge(rtmu, how='left', on='ym')

## SPF forecast dispersion
spf = pd.read_csv("data/SPF_Dispersion_PGDP_D2.csv", sep=";", decimal=",", na_values="#N/A", skiprows=9)
spf.columns = spf.columns.str.replace('[()+]', '.', regex=True)
# Replace 'Survey_Date.T.' with the correct column name for your date data
spf['year'] = pd.to_numeric(spf['Survey_Date.T.'].str[:4], errors='coerce')
spf['quarter'] = pd.to_numeric(spf['Survey_Date.T.'].str[5:6], errors='coerce')
# Filter rows where year >= 1990
spf = spf[spf['year'] >= 1990]
# Create 'yq' column by combining 'year' and 'quarter'
spf['yq'] = spf['year']*10 + spf['quarter']
# Rename columns
spf = spf.rename(columns={
    "PGDP_D2.T.": "PGDPD2T",
    "PGDP_D2.T.1.": "PGDPD2T1",
    "PGDP_D2.T.2.": "PGDPD2T2",
    "PGDP_D2.T.3.": "PGDPD2T3",
    "PGDP_D2.T.4.": "PGDPD2T4"
})
# Select 'yq' and all columns that start with "PGDPD2"
spf = spf.loc[:, spf.columns.str.startswith("PGDPD2") | (spf.columns == 'yq')]
# Perform left join
dataq = pd.merge(dataq, spf, how='left', on='yq')

# Define an empty dataframe
tbl = pd.DataFrame(np.nan, index=range(8), columns=range(5))
# Add data to first column
tbl.iloc[:, 0] = ["Intercept", "", "Slope", "", "$R^2$", "Observations", "Sample", ""]
# Define column names
tbl.columns = ["", "JLN", "JLN", "Rogers-Xu", "SPF PGDP"]
# Define regression models
mods = [
    smf.ols(formula='mpu ~ h_12', data=datam).fit(),
    smf.ols(formula='mpu ~ h_12', data=datam[datam['date'].dt.year >= 1999]).fit(),
    smf.ols(formula='mpu ~ mu', data=datam).fit(),
    smf.ols(formula='mpu ~ PGDPD2T4', data=dataq).fit()
]

for j, mod in enumerate(mods):
    se = np.sqrt(mod.get_robustcov_results(cov_type='HAC', maxlags=1).cov_params().diagonal())
    coefs = mod.params
    r_squared = mod.rsquared
    nobs = mod.nobs
    
    # Store results in tbl dataframe
    tbl.iloc[[0, 2], j+1] = ["{:.2f}".format(coefs[0]), "{:.2f}".format(coefs[1])]  # coeficients
    tbl.iloc[[1, 3], j+1] = ["[{:.2f}]".format(se[0]), "[{:.2f}]".format(se[1])]  # standard errors
    tbl.iloc[4, j+1] = round(r_squared, 2)  # R-squared
    tbl.iloc[5, j+1] = int(nobs)  # number of observations

# Define the row values
tbl.iloc[6, 1:4] = "Monthly"
tbl.iloc[6, 4] = "Quarterly"

# Set the date ranges
tbl.iloc[7, 1] = "1990:M1--2020:M6"
tbl.iloc[7, 2] = "1999:M1--2020:M6"
tbl.iloc[7, 3] = "1999:M9--2018:10"
tbl.iloc[7, 4] = "1990:Q1--2020:Q1"

# Print the dataframe
print(tbl)

# Output the dataframe to a LaTeX table
tbl.to_latex("output/table_B1.tex", index=False, header=False)