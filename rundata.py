import pandas as pd
import os

'''
This script helps determine variance thresholds based on my own data
'''

def calculate_variance_in_chunks(df, chunk_size=10):
    # Define the columns for which we need to calculate variance
    columns_to_analyze = ['heart rate', 'cadence', 'enhanced speed']
    
    # Initialize an empty list to store the results
    results = []
    # Process the DataFrame in chunks of 10 rows
    for start in range(0, len(df), chunk_size):
        end = start + chunk_size
        chunk = df[start:end]

        # Ensure 'timestamp' is in datetime format
        chunk['timestamp'] = pd.to_datetime(chunk['timestamp'])

        # Initialize a dictionary to store variances for the current chunk
        chunk_results = {'chunk_start': start, 'chunk_end': end - 1}

        # Calculate the correlation with 'timestamp' for each column
        for column in columns_to_analyze:
            state = []
            if column in chunk.columns:
                correlation_matrix = chunk[['timestamp', column]].corr()
                correlation_value = correlation_matrix.loc['timestamp', column]
                chunk_results[f'{column}_correlation'] = correlation_value

                state.append(stateDetermine(correlation_value))
                chunk_results[f'{column}_state'] = state

            else:
                chunk_results[f'{column}_correlation'] = None  # Handle missing columns
                state.append("unknown")

        results.append(chunk_results)
    # Convert the results list into a DataFrame
    variance_df = pd.DataFrame(results)
    
    return variance_df

def stateDetermine(value):
    # Correlation Coefficients (r)
    coefficients = {
        'slow': (-0.8, -0.4),
        'stable': (-0.4, 0.4),
        'high': (0.4, 0.8),
        'sprint': (0.8, 1),
        'stopped': (-1, -0.8)
    }
    try:
        float(value)
    except:
        return ""
    for state, (lower, upper) in coefficients.items():
        if lower < float(value) <= upper:
            return state
    return 'unknown'  # Return 'unknown' if the value doesn't fit any range

  



if __name__ == "__main__":
    # Folder containing the CSV files
    csv_folder = 'runningdata'
    
    # Initialize an empty DataFrame to hold all variances
    combined_variance_df = pd.DataFrame()

    # Process each CSV file in the folder
    for filename in os.listdir(csv_folder):
        if filename.endswith('.csv'):
            file_path = os.path.join(csv_folder, filename)
            print(f"Processing file: {file_path}")

            # Read the CSV file into a DataFrame
            df = pd.read_csv(file_path)

            # Calculate the variance in chunks
            variance_df = calculate_variance_in_chunks(df)

            # Add the filename to the variance DataFrame
            variance_df['source_file'] = filename

            # Append the variance DataFrame to the combined DataFrame
            combined_variance_df = pd.concat([combined_variance_df, variance_df], ignore_index=True)

    # Save the combined results to a new CSV file
    combined_variance_df.to_csv('final_run_results.csv', index=False)

    print("Variance calculation completed and saved to 'variance_results.csv'")
