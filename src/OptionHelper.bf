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

		// Shorthand for ParseOptions with heap allocated string. It is up to the user to delete it in case of an error.
		public Result<void, String> ParseOptions(StringView[] args) {
			String s = new String();
			if(ParseOptions(args, s) == .Err) return .Err(s);
			delete s;
			return .Ok;
		}

		public Result<void> ParseOptions(StringView[] args, String errmsg) {
			for(int i = 0; i < args.Count; i++) {
				if(args[i][0] != '-' || args[i].Length < 2) { //Short circuit
					Console.WriteLine($"Ignoring malformed option {args[i]} at {i}");
					continue;
				}

				if(args[i][1] == '-') { //Long options
					int indexOf = args[i].IndexOf('=');
					for(Option o in options) if(StringView(args[i], 2, indexOf == -1 ? args[i].Length - 2 : indexOf - 2).Equals(o.longName)) {
						if(o.hasVal) {
			 				if(indexOf == -1) {
								Console.WriteLine($"Option {o.longName} requires an argument but none was given.");
								continue;
							}
							o.value = StringView(args[i], indexOf + 1);
						}
						o.isSet = true;
						continue;
					}
					Console.WriteLine($"Unknown long option found '{args[i]}'");
					continue;
				} // End Long Options

				// (Concatenated) short options: -s "a" -p -d = -psd "a". 
				bool argConsumed = false; // Only one short option within a concatenated option set can require an argument
				charLoop: // Needed for control flow as we want to not only break the inner loop but also skip code handling unrecognized options.
				for(int j = 1; j < args[i].Length; j++) { // Go through all chars after '-'
					for(Option o in options) {
						if(o.shortName == args[i][j]) {
							if(!o.hasVal) {
								o.isSet = true; 
								continue charLoop; // Option found, skip rest
							}
							if(argConsumed) {
								if(errmsg != null) errmsg.Append("Concatenating multiple short options requiring arguments is not allowed!");
								return .Err;
							}
							if(i + 1 == args.Count) {
								Console.WriteLine($"Short option {o.shortName} requires an argument but none was given.");
								return .Ok; // We are the last arg anyway, so we might as well exit directly;
							}
							o.value = args[++i]; // Increment i to avoid parsing argument as an option
							argConsumed = true;
							continue charLoop; // Option found, skip rest
						}
					}
					Console.WriteLine($"Unknown short option found '{args[i][j]}'");
				}
			}
			return .Ok;
		}
	}
}
