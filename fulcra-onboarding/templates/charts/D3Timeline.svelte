<script>
  import { onMount } from 'svelte';
  import * as d3 from 'd3';

  // The raw data points to visualize on the timeline
  let { data = [], title = "Activity Timeline", color = "#64c466" } = $props();

  let container;
  let tooltip;

  onMount(() => {
    if (!data || data.length === 0) return;

    // Parse times
    const parsedData = data.map(d => ({
      ...d,
      date: new Date(d.time)
    })).sort((a, b) => a.date - b.date);

    // Dimensions
    const width = container.clientWidth;
    const height = 100;
    const margin = { top: 20, right: 30, bottom: 30, left: 30 };

    // Clear previous SVG if re-rendering
    d3.select(container).selectAll("*").remove();

    const svg = d3.select(container)
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .style("overflow", "visible");

    // Scales
    const x = d3.scaleTime()
      .domain(d3.extent(parsedData, d => d.date))
      .range([margin.left, width - margin.right]);

    // Axis
    const xAxis = d3.axisBottom(x)
      .ticks(5)
      .tickFormat(d3.timeFormat("%b %d, %H:%M"));

    svg.append("g")
      .attr("transform", `translate(0,${height - margin.bottom})`)
      .call(xAxis)
      .attr("color", "rgba(255,255,255,0.5)")
      .selectAll("text")
      .style("font-family", "inherit")
      .style("fill", "rgba(255,255,255,0.8)");

    // Tooltip Selection
    const tip = d3.select(tooltip);

    // Timeline Line
    svg.append("line")
      .attr("x1", margin.left)
      .attr("y1", (height - margin.bottom) / 2)
      .attr("x2", width - margin.right)
      .attr("y2", (height - margin.bottom) / 2)
      .attr("stroke", "rgba(255,255,255,0.2)")
      .attr("stroke-width", 2);

    // Data Points
    svg.selectAll(".dot")
      .data(parsedData)
      .enter()
      .append("circle")
      .attr("class", "dot")
      .attr("cx", d => x(d.date))
      .attr("cy", (height - margin.bottom) / 2)
      .attr("r", 6)
      .attr("fill", color)
      .attr("stroke", "rgba(0,0,0,0.5)")
      .attr("stroke-width", 2)
      .style("cursor", "pointer")
      .on("mouseover", (event, d) => {
        d3.select(event.currentTarget)
          .transition()
          .duration(100)
          .attr("r", 10)
          .attr("stroke", "#fff");

        tip.style("opacity", 1)
           .html(`<strong>${d.label || d.type}</strong><br/><span style="font-size: 0.85em; opacity: 0.8;">${d.details || d.size || ''}</span><br/><span style="font-size: 0.75em; color: ${color};">${d.date.toLocaleString()}</span>`)
           .style("left", (event.pageX + 10) + "px")
           .style("top", (event.pageY - 28) + "px");
      })
      .on("mousemove", (event) => {
        tip.style("left", (event.pageX + 10) + "px")
           .style("top", (event.pageY - 28) + "px");
      })
      .on("mouseout", (event) => {
        d3.select(event.currentTarget)
          .transition()
          .duration(200)
          .attr("r", 6)
          .attr("stroke", "rgba(0,0,0,0.5)");

        tip.style("opacity", 0);
      });
  });
</script>

<div class="timeline-wrapper">
  <h4>{title}</h4>
  <div class="chart-container" bind:this={container}></div>
  <div class="d3-tooltip" bind:this={tooltip} style="opacity: 0;"></div>
</div>

<style>
  .timeline-wrapper {
    margin: 2rem 0;
    padding: 1rem;
    background: rgba(0, 0, 0, 0.2);
    border-radius: 8px;
    border: 1px solid rgba(255,255,255,0.1);
  }

  h4 {
    margin: 0 0 1rem 0;
    color: rgba(255,255,255,0.9);
    font-weight: normal;
    font-size: 1.1rem;
  }

  .chart-container {
    width: 100%;
    height: 100px;
    position: relative;
  }

  .d3-tooltip {
    position: fixed;
    background: rgba(10, 20, 15, 0.95);
    border: 1px solid #5a7d65;
    padding: 0.75rem;
    border-radius: 6px;
    pointer-events: none;
    color: #fff;
    font-size: 0.9rem;
    box-shadow: 0 4px 12px rgba(0,0,0,0.5);
    backdrop-filter: blur(4px);
    z-index: 1000;
    transition: opacity 0.2s ease;
    line-height: 1.4;
  }
</style>
