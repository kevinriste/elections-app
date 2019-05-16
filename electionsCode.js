const globalAverage = 2.341782
const availableMinWeights = [
  0,
  0.05,
  0.1,
  0.15,
  0.2,
  0.25,
  0.3,
  0.35,
  0.4,
  0.45,
  0.5
]
const availableDecayFactors = [7, 14, 21, 28, 35, 42],
var minWeight = 0.05,
var decayFactor = 14.0

const res = await axios({
  method: "get",
  url:
    "https://warm-lake-79107.herokuapp.com/https://projects.fivethirtyeight.com/polls-page/president_primary_polls.csv"
});
var fiveThirtyEightDataset = await csv().fromString(res.data);

const res2 = await axios({
  method: "get",
  url:
    "https://warm-lake-79107.herokuapp.com/https://raw.githubusercontent.com/fivethirtyeight/data/master/pollster-ratings/pollster-ratings.csv"
});
var pollsterRatings = await csv().fromString(res2.data);

var selectedCandidates = availableCandidates().slice(0, 5);
var dateRange = [
  new Date(availableDates()[0]),
  new Date(availableDates().slice(-1)[0])
];
var availableDateRange = dateRange;
var selectedStates = availableStates();

var pollsWeighted = function() {
  let pollDates = [];
  let dt = new Date(
    Math.min(...bidenPollsOnly().map(a => a.medianDate))
  );
  let end = new Date(
    Math.max(...bidenPollsOnly().map(a => a.medianDate))
  );
  while (dt <= end) {
    pollDates.push(new Date(dt));
    dt.setDate(dt.getDate() + 1);
  }
  pollDates.push(new Date(dt));
  let weightedData = {};
  for (const date of pollDates) {
    for (let item of topCandidates) {
      if (!weightedData[item.answer]) weightedData[item.answer] = {};
      weightedData[item.answer][date] = {
        netPct: 0,
        netWt: 0,
        date: date
      };
    }
    for (const poll of bidenPollsOnlyStateFiltered()) {
      let datediff = Math.floor(
        (date - poll.medianDate) / (1000.0 * 60.0 * 60.0 * 24.0)
      );
      let totalWeight =
        Math.pow(0.5, datediff / decayFactor) * poll.pollWeight;
      totalWeight = totalWeight < minWeight ? 0 : totalWeight;
      totalWeight = datediff < 0 ? 0 : totalWeight;
      weightedData[poll.answer][date].netPct +=
        totalWeight * poll.pct;
      weightedData[poll.answer][date].netWt += totalWeight;
    }
  }

  let scatterData = [];
  for (let item of topCandidates) {
    scatterData.push({
      type: "scatter",
      label: item.answer,
      backgroundColor: item.color.dark,
      borderColor: item.color.dark,
      data: Object.values(weightedData[item.answer]).map(a => {
        return {
          x: a.date,
          y: a.netWt == 0 || a.netPct == 0 ? null : a.netPct / a.netWt
        };
      }),
      pointRadius: 0,
      fill: false
    });
  }

  return {
    datasets: scatterData
  };
}

var pollScatter = function() {
  let scatterData = [];
  for (let item of topCandidates) {
    scatterData.push({
      type: "scatter",
      label: item.answer,
      backgroundColor: item.color.light,
      borderColor: item.color.light,
      data: bidenPollsOnly
        .filter(a => a.answer == item.answer)
        .map(a => {
          return {
            x: a.medianDate,
            y: selectedStates.includes(a.state) ? a.pct : null
          };
        }),
      fill: false,
      showLine: false
    });
  }
  return {
    datasets: scatterData
  };
}


bidenPollsOnlyStateFiltered = function() {
  return bidenPollsOnly().filter(a =>
    selectedStates.includes(a.state)
  );
}

pollsScatterAndWeighted = function() {
  return {
    datasets: pollsWeighted.datasets.concat(
      pollScatter.datasets
    )
  };
}

var pollsScatterAndWeightedDateFiltered = function() {
  let holder = JSON.parse(
    JSON.stringify(pollsScatterAndWeighted())
  );
  holder.datasets.forEach(a => {
    a.data = a.data.filter(
      b =>
        (!dateRange[0] ||
          dateDiff(dateRange[0], b.x) >= 0) &&
        (!dateRange[1] ||
          dateDiff(b.x, dateRange[1]) >= 0)
    );
  });
  return holder;
}

var availableCandidates = function() {
  let bidenPolls = [
    ...new Set(
      pollsMapped()
        .filter(a => a.answer == "Biden")
        .map(a => a.question_id)
    )
  ];
  let bidenPollsOnly = pollsMapped().filter(
    a => a.party == "DEM" && bidenPolls.includes(a.question_id)
  );
  let candidates = [...new Set(bidenPollsOnly.map(a => a.answer))];
  candidates = candidates.map(a => {
    return {
      answer: a,
      total: 0,
      count: 0,
      avg: 0
    };
  });
  for (let candidate of candidates) {
    bidenPollsOnly
      .filter(
        a =>
          a.answer == candidate.answer &&
          dateDiff(a.medianDate, new Date()) < 14
      )
      .forEach(a => {
        candidate.total += a.pct;
        candidate.count += 1;
        candidate.avg = candidate.total / candidate.count;
      });
  }
  return candidates.sort((a, b) => (b.count > 7 ? b.avg : 0) - a.avg);
}

var availableDates = function() {
  let pollDates = [];
  let dt = new Date(
    Math.min(...bidenPollsOnly().map(a => a.medianDate))
  );
  let end = new Date(
    Math.max(...bidenPollsOnly().map(a => a.medianDate))
  );
  while (dt <= end) {
    pollDates.push(new Date(dt));
    dt.setDate(dt.getDate() + 1);
  }
  pollDates.push(new Date(dt).getTime());
  return pollDates.map(a => new Date(a).toLocaleDateString());
}

var availableStates = function() {
  let bidenPolls = [
    ...new Set(
      pollsMapped()
        .filter(a => a.answer == "Biden")
        .map(a => a.question_id)
    )
  ];
  let bidenPollsOnly = pollsMapped().filter(
    a => a.party == "DEM" && bidenPolls.includes(a.question_id)
  );
  return [...new Set(bidenPollsOnly.map(a => a.state))].sort();
}

var dateDiff = function(date1, date2) {
  return date2.difference(date1).inDays;
}

var bidenPollsOnly = function() {
  let bidenPolls = [
    ...new Set(
      pollsMapped()
        .filter(a => a.answer == "Biden")
        .map(a => a.question_id)
    )
  ];
  let bidenPollsOnly = pollsMapped().filter(
    a =>
      a.party == "DEM" &&
      topCandidates().map(a => a.answer).includes(a.answer) &&
      bidenPolls.includes(a.question_id)
  );
  return bidenPollsOnly;
}

var topCandidates = function() {
  let colors = shuffleArray(
    generateHslColors(selectedCandidates.length)
  );
  return selectedCandidates.map((a, index) => {
    return {
      answer: a.answer,
      color: colors[index]
    };
  });
}

var shuffleArray = function(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

var generateHslColors = function(amount) {
  let colors = [];
  let huedelta = Math.trunc(360 / amount);

  for (let i = 0; i < amount; i++) {
    let hue = i * huedelta;
    let s = randomVal(30, 95);
    colors.push({
      light: `hsl(${hue}, ${s}%,  80%)`,
      dark: `hsl(${hue}, ${s}%,  40%)`
    });
  }

  return colors;
}

var randomVal = function(min, max) {
  return Math.floor(Math.random() * (max - min) + 1) + min;
}

var pollsMapped = function() {
  return fiveThirtyEightDataset.map(a => {
    let medianDate =
      new Date(a.start_date).getTime() +
      (new Date(a.end_date).getTime() -
        new Date(a.start_date).getTime()) /
        2.0;
    let pollError =
      1.96 *
      Math.sqrt(((a.pct / 100) * (1 - a.pct / 100)) / a.sample_size) *
      100;
    let pollsterErrorAdjuster = pollsterRatings.find(
      b => b.Pollster == a.pollster
    );
    let pollsterError =
      globalAverage + !pollsterErrorAdjuster
        ? 0.0
        : pollsterErrorAdjuster["Predictive Plus-Minus"];
    let totalError = pollError + pollsterError;
    let ess = 6400 * (totalError ^ -2);
    let averageTotalError = pollError + globalAverage;
    let adjss = 6400 * (averageTotalError ^ -2);
    let pollWeight = ess / adjss;
    return {
      answer: a.answer,
      pct: a.pct / 100.0,
      state: a.state,
      question_id: a.question_id,
      medianDate: new Date(medianDate),
      pollWeight: pollWeight,
      party: a.party
    };
  });
}