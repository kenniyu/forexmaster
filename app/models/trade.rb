class Trade < ActiveRecord::Base
  enum status: [ :opening, :updating, :closing ]

  def self.create_trade(pair, size, mark)
    # sanity check
    return nil if size == 0

    # upcase the pair
    pair = pair.upcase

    # check for recently opened trade
    recently_opened = Trade.where(pair: pair, status: 0).order(created_at: :desc).first
    status = :opening

    found_closing = false

    if recently_opened
      pair_trades_since_open = Trade.where("created_at >= ? AND pair = ?", recently_opened.created_at, recently_opened.pair)

      # calculate pips
      total_pips = 0
      pair_trades_since_open.each do |past_trade|
        total_pips += past_trade.size
        if past_trade.closing?
          # found a later closing trade. we should start a new trade
          found_closing = true
          break
        end
      end
      total_pips += size.to_i

      if !found_closing
        # if curent size is 0, trade will be closed
        if total_pips == 0
          status = :closing
        else
          status = :updating
        end
      end
    else
      puts "No trade for this pair was recently opened"
    end

    # create actual trade
    trade = Trade.create!(pair: pair,
        status: status,
        size: size,
        mark: mark)
  end

  def self.history
    trades = Trade.all.order(created_at: :desc)
    formatted_trades = []
    trades.each do |trade|
      current_trade = {
        pair: trade.pair,
        size: trade.size,
        mark: "%0.5f" % trade.mark.to_f,
        status: Trade.statuses[trade.status],
        date: trade.created_at.to_time.to_i
      }
      puts current_trade
      formatted_trades << current_trade
    end
    return formatted_trades
  end

  def self.pnl(from_date = Date.new(2016,1,1), to_date = Date.tomorrow)
    trades = Trade.where("created_at >= ? AND created_at < ?", from_date, to_date).order(created_at: :asc)
    trades_bucket = Hash.new(0)
    date_with_profits = []

    initial_profit = 0
    initial_balance = 1000
    initial_date = Trade.first.created_at.to_time.to_i
    initial_trade = {
      "date": initial_date,
      "profit": initial_profit
    }

    settled_profits = 0
    trades.each do |trade|
      trades_bucket[trade.pair] += (trade.size * trade.mark.to_f)
      if trade.closing?
        profit = -1 * trades_bucket[trade.pair]
        profit /= 100 if trade.mark > 9
        h = {
          "date": trade.created_at.to_time.to_i,
          "profit": profit
        }
        date_with_profits << h
        trades_bucket[trade.pair] = 0
        settled_profits += profit
      end
    end

    total_return = 100 * settled_profits/initial_balance.to_f
    date_with_profits.unshift(initial_trade)
    closed_trades = {
      "closed_trades": date_with_profits,
      "initial_balance": initial_balance,
      "inception_date": initial_date,
      "settled_profits": settled_profits,
      "total_return": total_return.round(2)
    }
  end

  def self.open_positions
    # group trades by pair, get most recent one
    all_trades = Trade.all.group(:id, :pair).order(created_at: :desc).where(status: 0)
    trades_result = []
    all_trades.each do |trade|
      # calculate cost bases
      cost_basis = trade.cost_basis
      total_size = trade.total_size
      if cost_basis == 0
        next
      else
        trades_result << {
          pair: trade.pair,
          size: total_size,
          cost_basis: "%0.5f" % cost_basis.to_f
        }
      end
    end
    return trades_result
  end

  def total_size
    return 0 if !self.opening?
    pair_trades_since_open = Trade.where("created_at >= ? AND pair = ?", self.created_at, self.pair)

    total_size = 0
    pair_trades_since_open.each do |trade|
      return 0 if trade.closing?
      total_size += trade.size
    end

    return total_size
  end

  def cost_basis
    return 0 if !self.opening?
    pair_trades_since_open = Trade.where("created_at >= ? AND pair = ?", self.created_at, self.pair)

    marks = []
    sum = 0
    total_size = 0
    pair_trades_since_open.each do |trade|
      return 0 if trade.closing?

      sum += trade.size * trade.mark
      total_size += trade.size
    end

    cost_basis = sum/total_size

    # cost_basis = sum/factor/1000
    return cost_basis.abs
  end
end
