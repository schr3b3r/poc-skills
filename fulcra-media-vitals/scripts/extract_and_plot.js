const { execSync } = require('child_process');
const fs = require('fs');

let asciichart;
try { asciichart = require('asciichart'); } catch (e) {}

const fileArg = process.argv[2];
const metricArg = process.argv[3] || 'HeartRate';

if (!fileArg || !fs.existsSync(fileArg)) {
    console.error("Usage: node extract_and_plot.js <path_to_media_file> [MetricName]");
    process.exit(1);
}

console.log(`Analyzing media file: ${fileArg}`);

// 1. Extract EXIF / MediaInfo timing data
let startUtcStr = null;
let durationSeconds = 0;

try {
    // Try exiftool first for generic metadata
    const exifOutput = execSync(`exiftool -json "${fileArg}"`).toString();
    const metadata = JSON.parse(exifOutput)[0];
    
    // Look for standard video/photo creation dates
    const dateStr = metadata.CreationDate || metadata.CreateDate || metadata.DateTimeOriginal;
    
    if (dateStr) {
        // ExifTool format: "YYYY:MM:DD HH:MM:SS" (sometimes with timezone offset)
        // Convert "YYYY:MM:DD" to "YYYY-MM-DD"
        const cleanDateStr = dateStr.replace(/^(\d{4}):(\d{2}):(\d{2})/, '$1-$2-$3');
        const dateObj = new Date(cleanDateStr);
        if (!isNaN(dateObj)) {
            startUtcStr = dateObj.toISOString();
        }
    }
    
    // Extract duration if present
    if (metadata.Duration) {
        // Duration might be a number (seconds) or string like "0:02:16"
        if (typeof metadata.Duration === 'number') {
            durationSeconds = Math.round(metadata.Duration);
        } else if (typeof metadata.Duration === 'string' && metadata.Duration.includes(':')) {
            const parts = metadata.Duration.split(':');
            durationSeconds = (parseFloat(parts[0]) * 3600) + (parseFloat(parts[1]) * 60) + parseFloat(parts[2] || 0);
        } else {
            durationSeconds = Math.round(parseFloat(metadata.Duration));
        }
    }
} catch (e) {
    console.log("Failed to extract metadata via exiftool. Ensure it is installed.", e.message);
    process.exit(1);
}

if (!startUtcStr) {
    console.error("Could not determine a valid start time from the media file's metadata.");
    process.exit(1);
}

// If it's a photo (no duration), we'll pad a 5-minute window around the shot to see the HR context
if (durationSeconds <= 0) {
    console.log("No duration found (likely a photo). Using a 5-minute window around capture time.");
    durationSeconds = 300; 
    // Shift start time back by 2.5 minutes
    const s = new Date(startUtcStr);
    s.setSeconds(s.getSeconds() - 150);
    startUtcStr = s.toISOString();
}

const endDate = new Date(new Date(startUtcStr).getTime() + (durationSeconds * 1000));
const endUtcStr = endDate.toISOString();

console.log(`Media Bounds: ${startUtcStr} to ${endUtcStr} (${Math.round(durationSeconds)} seconds)`);
console.log(`Fetching ${metricArg} data from Fulcra...`);

// 2. Fetch Fulcra Metrics
let hrValues = [];
try {
    const cmd = `uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' metric-time-series --sample-rate 1 --agg-function mean ${metricArg} "${startUtcStr}" "${endUtcStr}"`;
    const jsonl = execSync(cmd).toString().trim();
    
    if (jsonl) {
        const lines = jsonl.split('\n');
        hrValues = lines.map(l => {
            try { return JSON.parse(l).mean_heart_rate; } catch(e) { return null; }
        }).filter(v => v !== null && v !== undefined);
    }
} catch (e) {
    console.error(`Failed to fetch metric data: ${e.message}`);
    process.exit(1);
}

// 3. Render
if (hrValues.length === 0) {
    console.log(`\nNo ${metricArg} data was recorded by your devices during this specific media window.`);
    console.log(`(Note: Apple Watches only sample heart rate every ~5-10 minutes unless actively in a Workout).`);
    process.exit(0);
}

const avg = Math.round(hrValues.reduce((a,b) => a+b, 0) / hrValues.length);
const max = Math.round(Math.max(...hrValues));
const min = Math.round(Math.min(...hrValues));

// Dynamic timezone
function getUserTimezone() {
    try {
        const output = execSync(`uv tool run 'git+https://github.com/fulcradynamics/fulcra-api-python.git@add-cli' user-info`).toString();
        return JSON.parse(output).preferences.timezone || 'UTC';
    } catch (e) {
        return 'UTC';
    }
}
const timezone = getUserTimezone();

const startLocal = new Date(startUtcStr).toLocaleTimeString('en-US', { timeZone: timezone, hour: '2-digit', minute:'2-digit' });
const endLocal = new Date(endUtcStr).toLocaleTimeString('en-US', { timeZone: timezone, hour: '2-digit', minute:'2-digit' });

console.log(`\n=========================================================`);
console.log(`🎬 Media File Vitals (${startLocal} - ${endLocal})`);
console.log(`=========================================================`);
console.log(`❤️  ${metricArg} | Avg: ${avg} | Min: ${min} | Max: ${max}\n`);

if (asciichart) {
    let plotData = hrValues;
    const MAX_POINTS = 80;
    if (hrValues.length > MAX_POINTS) {
        const step = Math.floor(hrValues.length / MAX_POINTS);
        plotData = hrValues.filter((_, i) => i % step === 0);
    }
    const config = { height: 10, colors: [ asciichart.red ] };
    console.log(asciichart.plot(plotData, config));
}
