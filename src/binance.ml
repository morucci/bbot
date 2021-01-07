open Core

module KFetcher = struct
  let pair_list =
    [
      "BTCUSDT";
      "ETHUSDT";
      "LTCUSDT";
      "XRPUSDT";
      "DOTUSDT";
      "ADAUSDT";
      "BCHUSDT";
      "BNBUSDT";
      "LINKUSDT";
      "XLMUSDT";
      "EOSUSDT";
      "XMRUSDT";
      "THETAUSDT";
      "TRXUSDT";
      "XEMUSDT";
      "VETUSDT";
      "XTZUSDT";
      "UNIUSDT";
      "AAVEUSDT";
      "SNXUSDT";
    ]

  let get_pair_url (pair : string) (period : string) : string =
    "https://api.binance.com/api/v3/klines?symbol=" ^ pair ^ "&interval="
    ^ period

  let get_tracker_pair_url (pair : string) : string =
    "https://www.binance.com/fr/trade/" ^ pair ^ "?layout=pro"

  let to_kline_record (kline : Binance_t.kline) : Ta.Kline.t =
    kline |> function
    | o_t, o_p, h_p, l_p, c_p, vol, c_t, _, trades, _, _, _ ->
        Ta.Kline.
          {
            o_t;
            o_p = o_p |> Float.of_string;
            h_p = h_p |> Float.of_string;
            l_p = l_p |> Float.of_string;
            c_p = c_p |> Float.of_string;
            vol = vol |> Float.of_string;
            c_t;
            trades;
          }
end
