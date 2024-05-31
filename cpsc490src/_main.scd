/*******************
Analog Input
Connect analog sources (e.g.: potentiometers, LDR, FSR) to analog input 0 and 1

AnalogIn returns a value from 0-1

.ar (analogPin: 0, mul: 1, add: 0)

analogPin:  Analog pin number to read. Pin numbers begin at 0. This value can be modulated at audiorate.

(c) 2017: Jonathan Reus, Marije Baalman, Giulio Moro, Andrew McPherson
*/

s = Server.default;

s.options.numAnalogInChannels = 2; // can only be 2, 4 or 8
s.options.numAnalogOutChannels = 2;
s.options.numDigitalChannels = 0;
s.options.maxLogins = 4;  	   // set max number of clients
s.options.bindAddress = "0.0.0.0"; // allow anyone on the network connect to this server

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.waitForBoot{
	"Server Booted".postln;
	
~ampDict = Dictionary.new;

~samples = CSVFileReader.read("melodica_decibals.csv", skipEmptyLines: true, startRow: 0);
~samples = ~samples.collect(_.collect(_.interpret)).postln;

~normalizeAndConvert = { |array|
	(array - array.maxItem()).dbamp;
};

~samples.do({ |item, i|
	var midi = item[0];
	var num = midi;
	item.removeAt(0);
	item = ~normalizeAndConvert.(item);
	~ampDict.put(midi, item);
};);

~ampArrayT = Array.fill(12, { Array.new(12)});

for(53, 84, {|i|
	var amps = ~ampDict.at(i);
	for(0, 11, {|j|
		~ampArrayT[j] = ~ampArrayT[j] ++ amps[j];
	});
});

~envArray = Array.fill(12, {|i| Env.new([~ampArrayT[i][0]] ++ ~ampArrayT[i], [53] ++ Array.fill(11, {1}))});

~numDown = Bus.control;
~noteCount = 1;

SynthDef(\melo, { |fund, amps #[0,0,0,0,0,0,0,0,0,0,0,0], gate |
	var freqs, snd, env, breath, filt, pan;
	breath = AnalogIn.kr(0);
	freqs = Array.fill(amps.size, {|in| in = in + 1; fund * in;});
	snd = SinOsc.ar(freqs, 0, amps) * breath.linlin(0.12, 1.00, 0.0, 0.20) * gate / ~noteCount;
	filt = LPF.ar(snd, breath.linlin(0.12, 1.00, 400, 5000));
	Out.ar(0, Pan2.ar(Mix.ar(snd), 0));
}).add;

SynthDef(\meloSlide, { |fund, amps #[0,0,0,0,0,0,0,0,0,0,0,0], gate |
	var fundNew, freqs, snd, env, breath, filt, pan;
	breath = AnalogIn.kr(0);
	fundNew = (fund * breath.linlin(0.12, 1, 1, 2)).cpsmidi.round(1).midicps;
	freqs = Array.fill(amps.size, {|in| in = in + 1; fundNew * in});
	snd = SinOsc.ar(freqs, 0, amps) * 0.2 * gate / ~noteCount;
	filt = LPF.ar(snd, breath.linlin(0.12, 1.00, 400, 5000));
	Out.ar(0, Pan2.ar(Mix.ar(snd), 0));
}).add;

SynthDef(\trumpet, { |fund = 400, mf = 1, im = 500, fb = 100|

	var cf, breath, en, m, c, p, lo, li, lfp, lfa, tra, mouse;
	breath = AnalogIn.kr(0); // amplitude envelope
	cf = fund;
	tra = SinOsc.kr(20, 0, Line.kr(0.5,0,0.125), 1); // transient
	lfp = LFNoise0.kr(10, 0.001 * cf);  // microrandomness for pitch
	lfa = LFNoise1.kr(10, 0.01, 1);  // microrandomness for amplitude
	m = SinOsc.ar(cf * mf, 0, im * (breath.linlin(0.12, 1, 0, 0.5) + 1)); // modulator
	c = SinOsc.ar(cf + lfp + m) * breath.linlin(0.12, 1, 0, 0.6) * lfa * tra / ~noteCount; // carrier
	p = Pan2.ar(c); // panning (of carrier and noise)

	Out.ar(0, p);

}).add;

SynthDef(\trumpetSlide, { |fund = 400, mf = 1, im = 500, fb = 100|

	var cf, breath, en, m, c, p, lo, li, lfp, lfa, tra, mouse;
	breath = AnalogIn.kr(0); // amplitude envelope
	cf = (fund * breath.linlin(0.12, 1, 1, 2)).cpsmidi.round(1).midicps;
	tra = SinOsc.kr(20, 0, Line.kr(0.5,0,0.125), 1); // transient
	lfp = LFNoise0.kr(10, 0.001 * cf);  // microrandomness for pitch
	lfa = LFNoise1.kr(10, 0.01, 1);  // microrandomness for amplitude
	m = SinOsc.ar(cf * mf, 0, im * (breath.linlin(0, 1, 0, 0.5) + 1)); // modulator
	c = SinOsc.ar(cf + lfp + m) * 0.4 * lfa * tra / ~noteCount; // carrier
	p = Pan2.ar(c); // panning (of carrier and noise)

	Out.ar(0, p);

}).add;

~synths = IdentityDictionary.new;
~meloAmps = ([-21.5, -14.1, -12.6, -24.9, -11.2, -25] + 11.2).dbamp;
~synthArray = [\melo, \meloSlide, \trumpet, \trumpetSlide];
~synthIndex = 0;

MIDIClient.init;
MIDIIn.connectAll;

MIDIdef.noteOn(\noteOnFunc, { |vel, midiNote, chan, src |
	var amps;
	amps = Array.fill(~envArray.size, {|i| ~envArray[i][midiNote]});
	if ( midiNote == 103,
		{ ~synthIndex = (~synthIndex + 1) % 4;
			// "synth changed".postln; //debug
			// ~synthIndex.postln; //debug
		},
		{
			// midiNote.postln; //debug
			// amps.postln; //debug
			~noteCount = ~noteCount + 1;
			~numDown.set(~noteCount);
			~synths.put(midiNote, Synth.new(~synthArray.at(~synthIndex), [\fund: midiNote.midicps, \amps: amps, \gate: 1]));
		}
	);
});

MIDIdef.noteOff(\noteOffFunc, {
	arg vel, nn, chan, src;
	// ~synths.at(nn).set(\gate, 0);
	if ( nn != 103,
		{ 
			~synths.at(nn).free;
			~noteCount = ~noteCount - 1;
			~numDown.set(~noteCount);
			
	} );
});
	
};

ServerQuit.add({ 0.exit }); // quit if the button is pressed
