import gleam/javascript/array
import shared/vote

pub type ChartData

pub fn votes_to_chartjs(votes: List(vote.Vote)) -> ChartData {
  do_votes_to_chartjs(array.from_list(votes))
}

@external(javascript, "./bar_chart_ffi.mjs", "votesToChartJS")
fn do_votes_to_chartjs(votes: array.Array(vote.Vote)) -> ChartData

@external(javascript, "./bar_chart_ffi.mjs", "init")
pub fn init(id: String, data: ChartData) -> Nil

@external(javascript, "./bar_chart_ffi.mjs", "update") 
pub fn update(id: String, data: ChartData) -> Nil