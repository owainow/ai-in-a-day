import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

# Load the generated Parquet file
generated_df = pd.read_parquet('microsoft_products_tuning_data.parquet')

# Print the first few rows and the column names to verify the structure
print(generated_df.head())
print(generated_df.columns)