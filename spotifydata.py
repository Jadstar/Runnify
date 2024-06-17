import pandas as pd

# Define the song states with the specified order
song_states = {
    "RECOVER": {
        "state": "RSTATE_RECOVER",
        "bpmRange": [0, float('inf')],  # BPM match cadence (high prio)
        "dance": [0.50, 0.85],
        "energy": [0.50, 0.85],
        "acoustic": [0, 0.10],
        "instrumental": [0, 0.40],
        "liveness": [0, 0.20],
        "speech": [0, 0.10]
    },
    "FALLOFF": {
        "state": "RSTATE_FALLOFF",
        "bpmRange": [0, float('inf')],  # BPM equal avg cadence, or slightly higher than current cadence (High prio)
        "happiness": [0.40, 0.9],
        "dance": [0.48, 0.80],
        "energy": [0.73, 1],
        "acoustic": [0, 0.60],
        "instrumental": [0, 0.15],
        "liveness": [0.05, 0.30],
        "speech": [0, 0.20]
    },
    "COOLDOWN": {
        "state": "RSTATE_COOLDOWN",
        "bpmRange": [0, float('inf')],  # BPM lower than current cadence (low prio)
        "dance": [0.45, 0.55],
        "energy": [0.60, 0.80],
        "acoustic": [0, 0.80],
        "instrumental": [0, 0.20],
        "liveness": [0, 0.25],
        "speech": [0, 0.50]
    },
    "RACE": {
        "state": "RSTATE_RACE",
        "bpmRange": [100, 200],  # BPM match ideal cadence ~175-180bpm (High prio)
        "dance": [0.05, 0.8],
        "energy": [0.82, 1.00],
        "acoustic": [0, 0.10],
        "instrumental": [0, 0.10],
        "liveness": [0.05, 0.6],
        "speech": [0, 0.20]
    },
    "TEMPO": {
        "state": "RSTATE_TEMPO",
        "bpmRange": [0, 1000],  # BPM match cadence (High prio)
        "dance": [0.15, 0.8],
        "energy": [0.60, 1],
        "acoustic": [0, 1],
        "instrumental": [0, 1],
        "liveness": [0.0, 0.80],
        "speech": [0, 0.28]
    },
    "WARMUP": {
        "state": "RSTATE_WARMUP",
        "bpmRange": [0, 200],  # BPM match cadence (low prio)
        "dance": [0.25, 0.85],
        "energy": [0.3, 1],
        "acoustic": [0, 0.8],
        "instrumental": [0, 0.5],
        "liveness": [0, 0.9],
        "speech": [0, 0.6]
    }
}


# Load the CSV file into a pandas DataFrame
csv_file = 'the_goated_run.csv'
df = pd.read_csv(csv_file)

# Function to check if a value is within a given range
def is_within_range(value, range_min, range_max):
    return range_min <= value <= range_max

# Function to determine the state of a song
def determine_state(song):
    for state_name, criteria in song_states.items():
        if all(
            is_within_range(song['Tempo'], criteria['bpmRange'][0], criteria['bpmRange'][1]) and
            is_within_range(song['Danceability'], criteria['dance'][0], criteria['dance'][1]) and
            is_within_range(song['Energy'], criteria['energy'][0], criteria['energy'][1]) and
            is_within_range(song['Acousticness'], criteria['acoustic'][0], criteria['acoustic'][1]) and
            is_within_range(song['Instrumentalness'], criteria['instrumental'][0], criteria['instrumental'][1]) and
            is_within_range(song['Liveness'], criteria['liveness'][0], criteria['liveness'][1]) and
            is_within_range(song['Speechiness'], criteria['speech'][0], criteria['speech'][1])
            for k in criteria.keys() if k not in ['state', 'bpmRange']
        ):
            return state_name
    return "UNKNOWN"

# Apply the function to each row in the DataFrame
df['State'] = df.apply(determine_state, axis=1)

# Save the DataFrame to a new CSV file with the extra column
output_csv_file = 'the_goated_run_with_statesv5.csv'
df.to_csv(output_csv_file, index=False)

# Display the DataFrame with the new 'State' column
print(df[['Spotify ID', 'Track Name', 'State']])
