import { Chart } from "chart.js/auto";

export function votesToChartJS(votesList) {
  const voteCounts = { yes: 0, no: 0, blank: 0 };
  
  for (const vote of votesList) {
    const voteType = vote.vote;
    if (voteType === "Yes") voteCounts.yes++;
    else if (voteType === "No") voteCounts.no++;
    else if (voteType === "Blank") voteCounts.blank++;
  }

  return {
    labels: ["Yes", "No", "Blank"],
    datasets: [{
      label: "Votes",
      data: [voteCounts.yes, voteCounts.no, voteCounts.blank],
      backgroundColor: [
        "oklch(70.4% 0.191 120.216)", // Green for Yes
        "oklch(70.4% 0.191 22.216)",  // Red for No  
        "oklch(74.6% 0.16 232.661)"   // Blue for Blank
      ],
      borderWidth: 1
    }]
  };
}

export function init(id, data) {
  const el = document.getElementById(id);
  const chart = new Chart(el, {
    type: "bar",
    data,
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            stepSize: 1
          }
        }
      }
    }
  });
  
  // Store chart instance on the element for updates
  el._chart = chart;
}

export function update(id, data) {
  const el = document.getElementById(id);
  if (el._chart) {
    el._chart.data = data;
    el._chart.update("none");
  }
}