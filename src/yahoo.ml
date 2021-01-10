open Base
open Async

(* API access: https://query1.finance.yahoo.com/v8/finance/chart/BN.PA?interval=1h
See yfinance: https://github.com/ranaroussi/yfinance/blob/master/yfinance/base.py *)

module KFetcher = struct
  let pair_list : string list = []

  let get_pair_url (_ : string) (_ : string) : string = ""

  let get_tracker_pair_url (_ : string) : string = ""

  let get_klines (_ : string) (_ : Report_t.period) :
      (Ta.Kline.t list, string) Result.t Deferred.t =
    let klines : Ta.Kline.t list = [] in
    Result.Ok klines |> return

  let interface =
    Provider.
      {
        pairs = pair_list;
        tracker_url = get_tracker_pair_url;
        fetcher = get_klines;
      }
end
