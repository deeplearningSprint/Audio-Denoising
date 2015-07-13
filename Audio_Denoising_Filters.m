hSound = dsp.AudioFileReader('sample.wav',...
                                         'SamplesPerFrame', 1024, ...
                                         'OutputDataType', 'double');
%Get the input sampling frequency
hInfo = audioinfo('sample.wav');
Fs = hInfo.SampleRate;

% Create a System object to play back audio to the sound card
hPlayer = dsp.AudioPlayer('SampleRate', Fs);
% Create a System object to write to an audio file
hOutputFile = dsp.AudioFileWriter('with_then_without_noise.wav',...
                                              'SampleRate', Fs);
% Create System objects for logging pure noise and filtered output signals
hLogNoise = dsp.SignalSink;
hLogOutput =dsp.SignalSink;
%Advance input audio by 5 seconds The first 5 seconds of the input do not contain any significant data,i.e
%about 100 frames. (@Fs =22050Hz, 1024 samples per frame)

for frame_index=1:100
    step(hSound);
end

%Extract the noise spectrum
%To obtain our “pure noise” signal, we use a 1-second portion of the
%signal, from 00:05 to 00:06 seconds, that has only the noise sound
for noise_frames = 1:20
    noise = step(hSound);
    step(hLogNoise, noise);
end

% Plot noise spectrum and identify noise frequencies
pwelch(hLogNoise.Buffer, [], [], 8192, Fs);
set(gcf,'Color','white');
%openfig('noise_peaks.fig');
% Noise peaks are observed at the following frequencies:
% 235Hz, 476Hz, 735Hz, 940Hz, 1180Hz
% Specifications for notch parametric equalizers
F01 = 235; F02 = 476; F03 = 735; F04 = 940; F05 = 1180;
N = 2; %Filter order
Gref = 0; %Reference gain
G0 = -20; %Attenuate by 20dB
Qa = 10;  %Higher Q-factor for fundamental and 1st harmonic
Qb = 5;   %Lower Q-factor for higher harmonics
f1 = fdesign.parameq('N,F0,Qa,Gref,G0',N,F01,Qa,Gref,G0,Fs);
f2 = fdesign.parameq('N,F0,Qa,Gref,G0',N,F02,Qa,Gref,G0,Fs);
f3 = fdesign.parameq('N,F0,Qa,Gref,G0',N,F03,Qb,Gref,G0,Fs);
f4 = fdesign.parameq('N,F0,Qa,Gref,G0',N,F04,Qb,Gref,G0,Fs);
f5 = fdesign.parameq('N,F0,Qa,Gref,G0',N,F05,Qb,Gref,G0,Fs);
% Specifications for peak parametric equalizer
N_peak = 8; %Use higher filter order for peak filter
F06 = 480;  %Center frequency to boost
Qc = 0.5;   %Use very low Q-factor for boost equalizer filter
G1 = 9;     %Boost gain by 9dB
f6 = fdesign.parameq('N,F0,Qa,Gref,G0',N_peak,F06,Qc,Gref,G1,Fs);
% Design filters and visualize responses
Hp1 = design(f1, 'butter');
Hp2 = design(f2, 'butter');
Hp3 = design(f3, 'butter');
Hp4 = design(f4, 'butter');
Hp5 = design(f5, 'butter');
Hp6 = design(f6, 'butter');
hFV = fvtool([Hp1 Hp2 Hp3 Hp4 Hp5 Hp6], 'Color', 'white');
legend(hFV,'NotchEQ #1', 'NotchEQ #2', 'NotchEQ #3', 'NotchEQ #4','NotchEQ #5','Peak EQ');
% Implement filters using second-order sections
hEQ1 = dsp.BiquadFilter('SOSMatrix',Hp1.sosMatrix,'ScaleValues',Hp1.ScaleValues);
hEQ2 = dsp.BiquadFilter('SOSMatrix',Hp2.sosMatrix,'ScaleValues',Hp2.ScaleValues);
hEQ3 = dsp.BiquadFilter('SOSMatrix',Hp3.sosMatrix,'ScaleValues',Hp3.ScaleValues);
hEQ4 = dsp.BiquadFilter('SOSMatrix',Hp4.sosMatrix,'ScaleValues',Hp4.ScaleValues);
hEQ5 = dsp.BiquadFilter('SOSMatrix',Hp5.sosMatrix,'ScaleValues',Hp5.ScaleValues);
hEQ6 = dsp.BiquadFilter('SOSMatrix',Hp6.sosMatrix,'ScaleValues',Hp6.ScaleValues);
%Filter 400 frames of input data
for frames = 1:400
    %Step through input WAV file one frame at a time
    input = step(hSound);
    %Apply notch EQ filters first, then peak EQ filter
    out1 = step(hEQ1, input);
    out2 = step(hEQ2, out1);
    out3 = step(hEQ3, out2);
    out4 = step(hEQ4, out3);        
    out5 = step(hEQ5, out4);
    denoised_sig = step(hEQ6, out5);
    %Play 200 frames of input signal, then 200 frames of filtered output
    %to compare original and filtered signals
    %Log the audio output to a WAV file
    if frames < 200
      step(hPlayer, input);
      step(hOutputFile, input);
    else 
       step(hPlayer, denoised_sig);
       step(hOutputFile, denoised_sig);
    end
   
   %Log filtered output to buffer
   step(hLogOutput, denoised_sig);
end

% Plot filtered signal spectrum

figure; pwelch(hLogOutput.Buffer, [], [], 8192, Fs);
set(gcf,'Color','white');

% Cleanup 

%Close input and output stream System objects

release(hSound);
release(hPlayer);
release(hOutputFile);
