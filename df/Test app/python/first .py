import pandas as pd

df = df_helper.get_table(parameter_name="input_table", parameter_display_name="Input Table", parameter_description="Input Raw Table"))
#
# Write your logic 
#

new_df = df.head(1000)

# Make sure to publish the data so that it become available in the UI or for other actions.
df_helper.publish(new_df)

