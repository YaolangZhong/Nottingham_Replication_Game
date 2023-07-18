import pandas as pd
import numpy as np
import pyreadr
from scipy import stats
import statsmodels.api as sm

file_path = "/Users/yaolangzhong/Nottingham_Replication/original_code/"

data = pyreadr.read_r(file_path + "data/straddle_returns_fomc.RData")['data']
# Convert the 'date' column to datetime type and create a new column 'ym'
data['date'] = pd.to_datetime(data['date'])
data['exp'] = pd.to_datetime(data['exp'])
data['ym'] = data['date'].dt.year*100 + data['date'].dt.month
# Filter data
data = data[(data['date'].dt.year >= 1994) &
            ((data['ym'] <= 200706) | (data['ym'] >= 200907))]

def return_stats(R):
    skew = stats.skew(R)
    kurt = stats.kurtosis(R)
    mod = sm.OLS(R, np.ones(len(R))).fit()
    tstat = mod.tvalues[0]
    res = pd.Series([f"{R.mean():4.1f}",
                     round(R.median(), 1),
                     round(R.std(), 1),
                     round(skew, 1),
                     round(kurt, 1),
                     round(tstat, 1),
                     round(abs(np.sqrt(8) * R.mean()) / R.std(), 1),
                     len(R)])
    res.index = ["Mean", "Median", "SD", "Skewness", "Kurtosis", "t-statistic", "Sharpe ratio", "Observations"]
    return res

# Define empty dataframes
tbl = pd.DataFrame(np.nan, index=range(8), columns=range(6))
tbl.columns = [f"ED{j}" for j in range(1, 7)]
tbl.index = ["Mean", "Median", "SD", "Skewness", "Kurtosis", "t-statistic", "Sharpe ratio", "Observations"]

tbl2 = tbl.copy()

# Loop through the columns
for j in range(1, 7):
    tmp = data[data['j']==j]
    # Relative returns
    tbl[f"ED{j}"] = return_stats(tmp['Rrel'].dropna())
    # Absolute returns
    tbl2[f"ED{j}"] = return_stats(tmp['Rabs'].dropna())

print(tbl)
print(tbl2)

with open("output/table_C3.tex", 'w') as f:
    f.write("& ED1 & ED2 & ED3 & ED4 & ED5 & ED6 \\\\ \n")
    f.write("\\midrule \n")
    f.write("\\multicolumn{6}{l}{\\emph{Relative returns}}\\\\ \n")
    f.write(tbl.iloc[0:7].to_latex(header=False, column_format='r' * 7))
    f.write("\\midrule \n")
    f.write("\\multicolumn{6}{l}{\\emph{Absolute returns}}\\\\ \n")
    f.write(tbl2.iloc[0:7].to_latex(header=False, column_format='r' * 7))
    f.write("\\midrule \n")
    f.write("Observations " + " ".join([f"& {x}" for x in tbl.iloc[7]]) + " \\\\ \n")
