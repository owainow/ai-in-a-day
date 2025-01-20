import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

# Sample data for tuning Falcon on Microsoft products in conversational format
data = [
    [{"role": "user", "content": "What are the latest features of Windows 11?"}, {"role": "assistant", "content": "The latest features of Windows 11 include a new Start Menu, virtual desktops, Snap Layouts, and more."}],
    [{"role": "user", "content": "Can you recommend a Microsoft laptop for gaming?"}, {"role": "assistant", "content": "I recommend the Microsoft Surface Laptop Studio for gaming. It has a powerful GPU and a high-refresh-rate display."}],
    [{"role": "user", "content": "What is Microsoft Azure?"}, {"role": "assistant", "content": "Microsoft Azure is a cloud computing platform and service created by Microsoft to build, test, deploy, and manage applications and services through Microsoft-managed data centers."}],
    [{"role": "user", "content": "How do I install Microsoft Office?"}, {"role": "assistant", "content": "To install Microsoft Office, go to the official Microsoft Office website, sign in with your Microsoft account, and follow the instructions to download and install the Office suite."}],
    [{"role": "user", "content": "What is the latest version of Microsoft Windows?"}, {"role": "assistant", "content": "The latest version of Microsoft Windows is Windows 11."}]
]

# Create a DataFrame
df = pd.DataFrame({"messages": data})

# Convert the DataFrame to a Parquet file
table = pa.Table.from_pandas(df)
pq.write_table(table, 'microsoft_products_tuning_data.parquet')

print("Parquet file 'microsoft_products_tuning_data.parquet' created successfully.")