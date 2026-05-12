const { execSync } = require('child_process');
const fs = require('fs');
const asciichart = require('asciichart');

const dataFile = process.argv[2];
if (!dataFile) {
    console.error("Usage: node plot_vitals.js <path_to_json_file>");
    process.exit(1);
}

if (!fs.existsSync(dataFile)) {
    console.error(`File not found: ${dataFile}`);
    process.exit(1);
}

const rawData = fs.readFileSync(dataFile, 'utf-8');
let events;
try {
    events = JSON.parse(rawData);
} catch (e) {
    console.error("Failed to parse JSON", e);
    process.exit(1);
}

if (!events || events.length === 0) {
    console.log("No events found in the given time range.");
    process.exit(0);
}


function getUserTimezone() {
    try {
        const output = execSync(`uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' user-info`).toString();
        const data = JSON.parse(output);
        return data.preferences.timezone || 'UTC';
    } catch (e) {
        return 'UTC';
    }
}
const timezone = getUserTimezone();


events.forEach(event => {
    const title = event.title || 'Untitled Meeting';
    const start = new Date(event.start_date).toLocaleTimeString('en-US', { timeZone: timezone, hour: '2-digit', minute:'2-digit' });
    const end = new Date(event.end_date).toLocaleTimeString('en-US', { timeZone: timezone, hour: '2-digit', minute:'2-digit' });
    
    console.log(`\n=========================================================`);
    console.log(`📅 ${title} (${start} - ${end})`);
    console.log(`=========================================================`);

    if (!event.heart_rate_series || event.heart_rate_series.length === 0) {
        console.log("No heart rate data for this event window.\n");
        return;
    }

    // Extract valid heart rate values
    const hrValues = event.heart_rate_series
        .map(pt => pt.mean_heart_rate)
        .filter(val => val !== null);

    if (hrValues.length === 0) {
        console.log("Heart rate data was empty/null for this event window.\n");
        return;
    }

    // Basic stats
    const avg = Math.round(hrValues.reduce((a,b) => a+b, 0) / hrValues.length);
    const max = Math.round(Math.max(...hrValues));
    const min = Math.round(Math.min(...hrValues));
    
    console.log(`❤️  Avg: ${avg} bpm | Min: ${min} bpm | Max: ${max} bpm\n`);

    // asciichart struggles if the array is way too large for terminal width.
    // Sample it down to ~80 data points if it's huge.
    let plotData = hrValues;
    const MAX_POINTS = 80;
    if (hrValues.length > MAX_POINTS) {
        const step = Math.floor(hrValues.length / MAX_POINTS);
        plotData = hrValues.filter((_, i) => i % step === 0);
    }

    const config = {
        height:  10,
        colors: [ asciichart.red ]
    };

    console.log(asciichart.plot(plotData, config));
    console.log("\n");
});
