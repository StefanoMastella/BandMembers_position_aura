%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sound source position auralization
%
% Guilherme Rosenthal and Stéfano Mastella Corrêa
%
% February 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; clc; close all;

%% Start SOFA to deal with Head-related transfer functions
% SOFAstart; %(uncomment if running for 1st time)

%% Loading music tracks and Fabian's HRTF Database
[bass, fs] = audioread('bass_30s.mp3');  
drums = audioread('drums_30s.mp3');
guitar = audioread('guitars_30s.mp3');
vocal = audioread('vocals_30s.mp3');

HRTF = SOFAload('FABIAN_HRIR_measured_HATO_0.sofa'); % Genetric HRTF 

fs_hrtf = HRTF.Data.SamplingRate;

%Obs: All signals must have the same sample rate
 
%% Variables rearrangement 
DFT = SOFAhrtf2dtf(HRTF);

%Fabian spacial downsample 
positions = DFT.SourcePosition;
DFT = sofaFit2Grid(DFT, positions);

%Break IRs from objects
HRTF = shiftdim(DFT.Data.IR,2);
HRTF = HRTF./max(abs(HRTF(:)));

%% Set the sound source position (Azimuth and Elevation)
%Getting spacial info from the HRTF (get_pos function)
azim = 0; elev = 10; pos_vocal = get_pos(positions, azim, elev); 
azim = 15; elev = 10; pos_bass = get_pos(positions, azim, elev); 
azim = 235; elev = 10; pos_guitar = get_pos(positions, azim, elev); 
azim = 3; elev = 10; pos_drums = get_pos(positions, azim, elev); 

HRTF_vocal = HRTF(:,pos_vocal,:); HRTF_bass = HRTF(:,pos_bass,:);
HRTF_guitar = HRTF(:,pos_guitar,:); HRTF_drums = HRTF(:,pos_drums,:);

%% Convolve audio and HRTF
nfft = length(vocal)+length(HRTF_vocal)-1;

%Convolving Vocals 
conv_vocal_HRTF_freq = fft(vocal,nfft) .* fft(squeeze(HRTF_vocal),nfft);
conv_vocal_HRTF_time = real(ifft(conv_vocal_HRTF_freq,nfft));

%Convolving bass
conv_bass_HRTF_freq = fft(bass,nfft) .* fft(squeeze(HRTF_bass),nfft);
conv_bass_HRTF_time = real(ifft(conv_bass_HRTF_freq,nfft));

%Convolving guitar
conv_guitar_HRTF_freq = fft(guitar,nfft) .* fft(squeeze(HRTF_guitar),nfft);
conv_guitar_HRTF_time = real(ifft(conv_guitar_HRTF_freq,nfft));

%Convolving drums
conv_drums_HRTF_freq = fft(drums,nfft) .* fft(squeeze(HRTF_drums),nfft);
conv_drums_HRTF_time = real(ifft(conv_drums_HRTF_freq,nfft));

%% Save audio file
Auralized_signal = conv_vocal_HRTF_time + conv_bass_HRTF_time + ...
    conv_guitar_HRTF_time + conv_drums_HRTF_time;
output = Auralized_signal./max(abs(Auralized_signal(:)))*0.95; %One can also save separate files
audiowrite('modified_audio_track.wav', output, fs);

% ===========================================================================%
%% Useful function
% Find the nearest HRTF position
function pos_idx = get_pos(positions, azim, elev)
    [~,pos_idx] = min(sqrt((positions(:,1) - azim).^2 + ...
                           (positions(:,2) - elev).^2));
end
