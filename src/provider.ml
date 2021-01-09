open Async

type fetcher_i = {
  pairs : string list;
  tracker_url : string -> string;
  fetcher :
    string -> Report_t.period -> (Ta.Kline.t list, string) Result.t Deferred.t;
}

type klines_fetcher_t =
  [ `ONE_D | `ONE_H ] -> (Ta.Kline.t list, string) Result.t Deferred.t
