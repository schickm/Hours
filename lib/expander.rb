require 'time'

class Expander
  def run(data,params={})
    merge_date_time(walk(data,params).flatten)
  end

  def merge_date_time(data)
    ret = []

    data.each do |d|
      time = d.delete(:time)
      s = time[:start]
      e = time[:end]
      date = d.delete(:date)
      d[:start] = Time.mktime(date.year, date.mon, date.mday, s.hour, s.min)
      end_time = Time.mktime(date.year, date.mon, date.mday, e.hour, e.min)
      # if end is greater than start, then we wrapped around a day, so add one
      if s > e
        end_time = end_time + (60 * 60 * 24)
      end
      d[:end] = end_time
    end

    return data
  end

  def walk(data,params={})
    if data == [] || data == nil
      return []
    else
      ret = []
      if data.class == Hash
        data.each do |k,v|
          # here we merge into another var because params will stick around after each loop
          ps = merge_data(params, k)
          ret.push(walk(v, ps))
        end
        return ret
      elsif data.class == Array
        data.each do |item|
          ret.push(walk(item, params))
        end
        return ret
      elsif data.class == String
        params = merge_data(params, data)
        return ret.push(params)
      end
    end
  end

  def merge_data(val, data)
    # if it's a date /m[m]/d[d]/yy[yy]
    if r = data.match(/^[\s\t]*?(\d{1,2})\/(\d{1,2})\/(\d{2,4})[\s\t]*?$/)
      year = r[3]
      # add on 20 for short year if needed
      if year.length == 2
        year = "20" + year
      end
      val.merge({:date => Time.mktime(year, r[1], r[2])})
    # if it's a time span
    elsif r = data.match(/^[\s\t]*?(\d{1,2}:\d{2}(?:[aA]|[pP])[mM])[\s\t]*?-[\s\t]*?(\d{1,2}:\d{2}(?:[aA]|[pP])[mM])[\s\t]*?$/)
      val.merge({:time => {:start => Time.parse(r[1]), :end => Time.parse(r[2])}})
    # if it's a hourly rate
    elsif r = data.match(/^\$([\d.]+)$/)
      val.merge({:rate => r[1].to_i})
    # if nothing matches, then it's just a label
    elsif data.class == String
      val.merge({:label => data})
    end
  end
end
