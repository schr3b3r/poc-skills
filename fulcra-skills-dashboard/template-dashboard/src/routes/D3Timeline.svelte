<script>
  import { onMount } from 'svelte';
  import * as d3 from 'd3';

  // The raw data points to visualize on the timeline
  let { data = [], title = "Activity Timeline", color = "#64c466" } = $props();

  /** @type {HTMLElement} */
  let container;
  
  /** @type {number | null} */
  let hoverIndex = $state(null);

  // Parse times
  let parsedData = $derived(data.map(d => ({
    ...d,
    date: new Date(d.time || d.date)
  })).sort((a, b) => a.date - b.date));

  let displayedDetails = $derived.by(() => {
      if (!parsedData || parsedData.length === 0) return [];
      let startIndex = hoverIndex !== null ? hoverIndex : parsedData.length - 1;
      let details = [];
      for (let i = 0; i < 5; i++) {
          let idx = startIndex - i;
          if (idx >= 0 && idx < parsedData.length) {
              details.push({ item: parsedData[idx], isHovered: hoverIndex === idx });
          }
      }
      return details;
  });

  function getAnimal(d) {
      if (d.type === 'backup' || (d.label && d.label.toLowerCase().includes('backup'))) return '🐢';
      if (d.type === 'annotation' || (d.label && d.label.toLowerCase().includes('note'))) return '🐕';
      if (d.label && d.label.toLowerCase().includes('jam')) return '🐎';
      return '🐉';
  }

  function getTier(d) {
      if (d.type === 'backup' || (d.label && d.label.toLowerCase().includes('backup'))) return 'Archival';
      if (d.type === 'annotation' || (d.label && d.label.toLowerCase().includes('note'))) return 'Annotation';
      return 'Event';
  }

  onMount(() => {
    if (!parsedData || parsedData.length === 0) return;

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

    // Timeline Line
    svg.append("line")
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
        
        // Find index
        hoverIndex = parsedData.findIndex(item => item === d);
      })
      .on("mouseout", (event) => {
        d3.select(event.currentTarget)
          .transition()
          .duration(200)
          .attr("r", 6)
          .attr("stroke", "rgba(0,0,0,0.5)");

        hoverIndex = null;
      });
  });
</script>

<div class="timeline-wrapper">
  <h4>{title}</h4>
  <div class="chart-container" bind:this={container}></div>

  <div class="mt-4 space-y-4" style="margin-top: 1rem; display: flex; flex-direction: column; gap: 1rem;">
    {#each displayedDetails as {item: detail, isHovered}}
      <div style="display: flex; gap: 1rem; align-items: flex-start; background: rgba(10, 20, 15, 0.4); padding: 1rem; border: 1px solid {isHovered ? 'rgba(100, 196, 102, 0.8)' : 'rgba(90, 125, 101, 0.3)'}; border-radius: 6px; position: relative; overflow: hidden; transition: all 0.3s; box-shadow: {isHovered ? '0 0 10px rgba(100, 196, 102, 0.3)' : 'none'}; transform: {isHovered ? 'scale(1.02)' : 'scale(1)'};">
        <!-- Bubble tail -->
        <div style="position: absolute; left: 4.5rem; top: 2rem; width: 1rem; height: 1rem; background: rgba(20, 30, 25, 1); border-left: 1px solid {isHovered ? 'rgba(100, 196, 102, 0.8)' : 'rgba(90, 125, 101, 0.3)'}; border-top: 1px solid {isHovered ? 'rgba(100, 196, 102, 0.8)' : 'rgba(90, 125, 101, 0.3)'}; transform: rotate(-45deg); z-index: 0; transition: all 0.3s;"></div>
        
        <div style="width: 3rem; height: 4rem; background: rgba(30, 40, 35, 1); flex-shrink: 0; display: flex; align-items: center; justify-content: center; padding: 0.375rem; border: 1px solid {isHovered ? 'rgba(100, 196, 102, 0.8)' : 'rgba(90, 125, 101, 0.5)'}; z-index: 10; position: relative; clip-path: polygon(0 0, 100% 0, 100% 70%, 50% 100%, 0 70%); filter: drop-shadow(0 0 5px {isHovered ? 'rgba(100, 196, 102, 0.8)' : 'rgba(90, 125, 101, 0.5)'}); transition: all 0.3s;">
          <div style="font-size: 1.5rem; filter: drop-shadow(2px 2px 2px rgba(0,0,0,0.8));">
            {getAnimal(detail)}
          </div>
        </div>
        
        <div style="flex: 1; background: rgba(20, 30, 25, 1); border: 1px solid {isHovered ? 'rgba(100, 196, 102, 0.5)' : 'rgba(90, 125, 101, 0.3)'}; padding: 0.75rem; border-radius: 6px; z-index: 10; position: relative; box-shadow: 0 4px 6px rgba(0,0,0,0.1); transition: all 0.3s;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.25rem; border-bottom: 1px solid {isHovered ? 'rgba(100, 196, 102, 0.3)' : 'rgba(90, 125, 101, 0.2)'}; padding-bottom: 0.5rem; transition: all 0.3s;">
            <h4 style="color: {isHovered ? '#fff' : color}; font-weight: bold; margin: 0; font-family: serif; display: flex; align-items: center; gap: 0.5rem; font-size: 0.95rem; transition: color 0.3s;">
              {detail.date.toLocaleString(undefined, { weekday: 'short', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
            </h4>
            <span style="font-size: 0.65rem; font-weight: bold; text-transform: uppercase; letter-spacing: 0.05em; padding: 0.125rem 0.5rem; border-radius: 2px; background: {isHovered ? 'rgba(100, 196, 102, 0.2)' : 'rgba(90, 125, 101, 0.2)'}; color: {isHovered ? '#fff' : color}; border: 1px solid {isHovered ? 'rgba(100, 196, 102, 0.5)' : 'rgba(90, 125, 101, 0.3)'}; transition: all 0.3s;">
              {getTier(detail)}
            </span>
          </div>
          <p style="color: {isHovered ? 'rgba(255,255,255,1)' : 'rgba(255,255,255,0.8)'}; font-family: serif; font-size: 0.875rem; line-height: 1.6; margin-top: 0.5rem; margin-bottom: 0; transition: color 0.3s;">
            <strong style="color: {isHovered ? '#fff' : color}; transition: color 0.3s;">{detail.label || detail.type}</strong><br/>
            {detail.details || detail.size || ''}
          </p>
        </div>
      </div>
    {/each}
  </div>
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
</style>
