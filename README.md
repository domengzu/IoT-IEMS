# IoT-Based Indoor Environmental Monitoring System (IEMS)

An open-source solution for monitoring indoor environmental factors using IoT sensors and real-time cloud connectivity. This project leverages Flutter for cross-platform app development and Supabase for backend data management.

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/96f1f3f2-23d7-4ba2-b7c8-73d4570296b3" />

## Features

- **Multi-Sensor Monitoring**: Tracks temperature, humidity (DHT11), noise levels, and gas concentration.
- **Real-Time Data**: Live updates and dashboard visualization with sensor data.
- **Threshold Alerts**: Customizable notification settings for temperature, noise, and gas thresholds.
- **Data History**: Retains recent readings.
- **Modular Architecture**: Clean code separation for sensors, services, and dashboard UI.
- **Cross-Platform**: Runs on Android via Flutter.

## Technologies Used

- **Flutter**: Mobile app framework.
- **Supabase**: Real-time backend for sensor data storage.
- **DHT11 Sensor**: Measures temperature and humidity.
- **Noise Sensor**: Measures environmental noise in decibels.
- **Gas Sensor**: Detects gas concentration for air quality assessment.

## System Architecture

- **Sensor Nodes**: Collect data and send readings to Supabase.
- **Supabase**: Handles real-time database changes and streams updates to the app.
- **Flutter App**: Visualizes and alerts users to environmental conditions.

## Getting Started

1. **Clone the Repository**
    ```sh
    git clone https://github.com/domengzu/IoT-IEMS.git
    cd IoT-IEMS
    ```

2. **Install Dependencies**
    - Make sure you have [Flutter](https://docs.flutter.dev/get-started/install) installed.
    - Run:
        ```sh
        flutter pub get
        ```

3. **Configure Supabase**
    - Set up a [Supabase](https://supabase.com/) project.
    - Add required tables: `dht11_readings`, `noise_readings`, `gas_readings`.
    - Update your Supabase credentials in the app.

4. **Run the App**
    - Use:
        ```sh
        flutter run
        ```
    - The app is ready for Android/iOS deployment.

## Usage

- **Dashboard**: View live sensor readings.
- **Refresh**: Manually refresh or wait for real-time updates.
- **Settings**: Adjust notification thresholds for environmental parameters.

## Contributing

Pull requests and suggestions are welcome! For major changes, please open an issue first to discuss what you would like to change.
