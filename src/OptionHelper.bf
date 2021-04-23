using System;
using System.Collections;

namespace cli_beef {

	struct Option : IDisposable {
		public String longName;
		public char8 shortName;
		public bool isSet = default;
		public StringView value = default;
		public bool hasVal;

		public this(StringView key, bool hasVal, char8 shortName) {
			this.longName = new String(key);
			this.hasVal = hasVal;
			this.shortName = shortName;
		}

		public void Dispose() {
			delete longName;
		}
	}

	public class OptionHelper {
		private List<Option> options = new .();

		public ~this() {
			for(Option o in options) o.Dispose();
			delete options;
		}

		public void DefineOption(StringView longName, bool hasArg, char8 short = 0) {
			options.Add(.(longName, hasArg, short));
		}

		public bool IsSet(StringView longName) {
			for(Option i in options) if(longName.Equals(i.longName)) return i.isSet;
			return false;
		}

		public Result<StringView, StringView> GetOpt(StringView longName, String errOut) {
			for(Option i in options) if(longName.Equals(i.longName)) {
				if(!i.hasVal) return .Err(errOut..Append("Option ")..Append(longName)..Append(" does not take in values!"));
				return i.isSet ? .Ok(i.value) : .Err(errOut..Append("Option ")..Append(longName)..Append(" is not set!"));
			}
			return .Err(errOut..Append("Option ")..Append(longName)..Append(" does not exist!"));
		}

		public Result<void> ParseOptions(StringView[] args) {
			for(int i = 0; i < args.Count; i++) {
				if(args[i][0] == '-') {
					if(args[i].Length < 2) { //Short circuit to prevent out of bounds memory access
						Console.WriteLine($"Ignoring malformed option '-' at {i}");
						continue;
					}
					if(args[i][1] == '-') { //Long options
						int indexOf = args[i].IndexOf('=');
						for(Option o in options) if(StringView(args[i], 2, indexOf == -1 ? args[i].Length - 2 : indexOf - 2).Equals(o.longName)) {
							if(o.hasVal) {
				 				if(indexOf == -1) {
									Console.WriteLine($"Option {o.longName} requires an argument but none was given.");
									return .Err;
								}
								o.value = StringView(args[i], indexOf + 1);
							}
							o.isSet = true;
							continue;
						}
						Console.WriteLine($"Unknown long option found '{args[i]}'");
						continue;
					} // End Long Options
					for(Option o in options) if(o.shortName == args[i][1]) {
						if(o.hasVal) {
							if(i + 1 == args.Count) {
								Console.WriteLine($"Option {o.longName} requires an argument but none was given.");
								return .Err;
							}
							o.value = args[++i]; // Increment to prevent double parsing
						}
						o.isSet = true;
						continue;
					}
					Console.WriteLine($"Unknown short option found '{args[i]}'");
					continue;
				}
			}
			return .Ok;
		}
	}
}
