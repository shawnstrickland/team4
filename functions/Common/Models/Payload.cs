using System.Collections.Generic;

namespace Common.Models;
public class Payload {
    public List<Record> Records {get; set; }
    public string eventTime { get; set; }
}