const { execSync } = require('child_process');
const fs = require('fs');

// Ensure we don't crash if asciichart isn't installed. We can fallback to simple text output.
let asciichart;
try {
    asciichart = require('asciichart');
} catch (e) {
    console.log("[Note: 'asciichart' package not found. Skipping graph rendering.]");
}

const transcriptFile = process.argv[2];
const eventsDataFile = process.argv[3];
const meetingTitle = process.argv[4];

if (!transcriptFile || !eventsDataFile || !meetingTitle) {
    console.error("Usage: node align_transcript.js <transcript.txt> <combined_data.json> \"<Meeting Title>\"");
    process.exit(1);
}

// 1. Load the pre-fetched combined JSON data
const rawData = fs.readFileSync(eventsDataFile, 'utf-8');
const events = JSON.parse(rawData);

// Find the specific meeting
const meetings = events.filter(e => e.title === meetingTitle && e.heart_rate_series && e.heart_rate_series.length > 0);
let meeting = null;

for (const m of meetings) {
    const hrValues = m.heart_rate_series.map(pt => pt.mean_heart_rate).filter(val => val !== null);
    if (hrValues.length > 0) {
        meeting = m;
        break; // Found one with actual heart rate data
    }
}

if (!meeting) {
    console.error("No instance of the meeting found with valid heart rate data.");
    process.exit(1);
}

// 2. Parse Transcript
const content = fs.readFileSync(transcriptFile, 'utf-8');
const lines = content.split('\n');
const utterances = [];

let currentSpeaker = null;
let currentOffsetSeconds = 0;
let currentText = [];

const timeRegex = /([a-zA-Z0-9\s.\(\)]+)\s+((\d+:)?\d+:\d+)/;

const parseOffset = (timeStr) => {
    const parts = timeStr.split(':').reverse();
    let seconds = parseInt(parts[0], 10);
    seconds += parseInt(parts[1], 10) * 60;
    if (parts[2]) seconds += parseInt(parts[2], 10) * 3600;
    return seconds;
};

for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    
    const match = line.match(timeRegex);
    if (match && line.endsWith(match[2])) {
        if (currentSpeaker) {
            utterances.push({
                speaker: currentSpeaker.trim(),
                offsetSeconds: currentOffsetSeconds,
                text: currentText.join(' ').trim()
            });
        }
        currentSpeaker = match[1];
        currentOffsetSeconds = parseOffset(match[2]);
        currentText = [];
    } else {
        if (currentSpeaker) {
            currentText.push(line);
        }
    }
}
if (currentSpeaker) {
    utterances.push({
        speaker: currentSpeaker.trim(),
        offsetSeconds: currentOffsetSeconds,
        text: currentText.join(' ').trim()
    });
}

// 3. Align Data
const hrValues = meeting.heart_rate_series
    .map(pt => pt.mean_heart_rate)
    .filter(val => val !== null);

const avg = Math.round(hrValues.reduce((a,b) => a+b, 0) / hrValues.length);
const max = Math.round(Math.max(...hrValues));
const min = Math.round(Math.min(...hrValues));


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

const meetingStartLocal = new Date(meeting.start_date).toLocaleTimeString('en-US', { timeZone: timezone, hour: '2-digit', minute:'2-digit' });

console.log(`\n=========================================================`);
console.log(`📅 ${meeting.title} (${meetingStartLocal})`);
console.log(`=========================================================`);
console.log(`❤️  Avg: ${avg} bpm | Min: ${min} bpm | Max: ${max} bpm\n`);

let plotData = hrValues;
const MAX_POINTS = 80;
let step = 1;
if (hrValues.length > MAX_POINTS) {
    step = Math.floor(hrValues.length / MAX_POINTS);
    plotData = hrValues.filter((_, i) => i % step === 0);
}

if (asciichart) {
    const config = { height: 10, colors: [ asciichart.red ] };
    console.log(asciichart.plot(plotData, config));
}
console.log("\n--- Key Heart Rate Moments & Transcripts ---\n");

const topMoments = meeting.heart_rate_series
    .map((pt, idx) => ({ hr: pt.mean_heart_rate, secondsIntoMeeting: idx }))
    .filter(pt => pt.hr !== null)
    .sort((a, b) => b.hr - a.hr)
    .slice(0, 5); 

topMoments.sort((a, b) => a.secondsIntoMeeting - b.secondsIntoMeeting);

topMoments.forEach(moment => {
    let activeUtterance = null;
    for (let u of utterances) {
        if (u.offsetSeconds <= moment.secondsIntoMeeting) {
            activeUtterance = u;
        } else {
            break;
        }
    }

    const min = Math.floor(moment.secondsIntoMeeting / 60);
    const sec = moment.secondsIntoMeeting % 60;
    const timeStr = `${min}:${sec.toString().padStart(2, '0')}`;

    console.log(`⏱️  [${timeStr}] Heart Rate Spiked to: ${Math.round(moment.hr)} bpm`);
    if (activeUtterance) {
        const textPreview = activeUtterance.text.length > 80 
            ? activeUtterance.text.substring(0, 80) + "..." 
            : activeUtterance.text;
        console.log(`   🗣️  ${activeUtterance.speaker}: "${textPreview}"`);
    } else {
        console.log(`   🗣️  (No active speaker detected)`);
    }
    console.log('');
});

