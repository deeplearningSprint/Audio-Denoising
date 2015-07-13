fprintf('--- Audio Signal Denoising using Spectral Subtraction ---\n\n');
%load noise sound example
[y,Fe]=audioread('sample.wav');
x=y(100000:end,1).';  %remove the beginning of the sample
Nx=length(x);

%algorithm parameters
apriori_SNR=1;  %select 0 for aposteriori SNR estimation and 1 for apriori
alpha=0.05;      %only used if apriori_SNR=1
beta1=0.5;
beta2=1;
lambda=3;

%STFT parameters
NFFT=1024;
window_length=round(0.031*Fe); 
window=hamming(window_length);
window = window(:);
overlap=floor(0.45*window_length); %number of windows samples without overlapping

%Signal parameters
t_min=0.4;    %interval for learning the noise
t_max=1.00;   %spectrum (in second)

%construct spectrogram 
[S,F,T] = spectrogram(x+i*eps,window,window_length-overlap,NFFT,Fe); %put a short imaginary part to obtain two-sided spectrogram
[Nf,Nw]=size(S);

%Noisy spectrum extraction
t_index=find(T>t_min & T<t_max);
absS_noise=abs(S(:,t_index)).^2;
noise_spectrum=mean(absS_noise,2); %average spectrum of the noise 
noise_specgram=repmat(noise_spectrum,1,Nw);

%Estimate SNR
absS=abs(S).^2;
SNR_est=max((absS./noise_specgram)-1,0); 
if apriori_SNR==1
    SNR_est=filter((1-alpha),[1 -alpha],SNR_est);
end  

%Compute Attenuation Map
an_lk=max((1-lambda*((1./(SNR_est+1)).^beta1)).^beta2,0); 
STFT=an_lk.*S;

%Compute Inverse STFT
ind=mod((1:window_length)-1,Nf)+1;
output_signal=zeros((Nw-1)*overlap+window_length,1);

for indice=1:Nw %Overlapp add technique
    left_index=((indice-1)*overlap) ;
    index=left_index+[1:window_length];
    temp_ifft=real(ifft(STFT(:,indice),NFFT));
    output_signal(index)= output_signal(index)+temp_ifft(ind).*window;
end

%-----------------    Display Figure   ------------------------------------      

%show temporal signals
figure
subplot(2,1,1);
t_index=find(T>t_min & T<t_max);
plot([1:length(x)]/Fe,x);
xlabel('Time (s)');
ylabel('Amplitude');
hold on;
noise_interval=floor([T(t_index(1))*Fe:T(t_index(end))*Fe]);
plot(noise_interval/Fe,x(noise_interval),'r');
hold off;
legend('Original signal','Noise Only');
title('Original Sound');
%show denoised signal
subplot(2,1,2);
plot([1:length(output_signal)]/Fe,output_signal );
xlabel('Time (s)');
ylabel('Amplitude');
title('Sound without noise');

%show spectrogram
t_epsilon=0.001;
figure
S_one_sided=max(S(1:length(F)/2,:),t_epsilon); %keep only the positive frequency
pcolor(T,F(1:end/2),10*log10(abs(S_one_sided))); 
shading interp;
colormap('hot');
title('Spectrogram: speech + noise');
xlabel('Time (s)');
ylabel('Frequency (Hz)');

figure
S_one_sided=max(STFT(1:length(F)/2,:),t_epsilon); %keep only the positive frequency
pcolor(T,F(1:end/2),10*log10(abs(S_one_sided))); 
shading interp;
colormap('hot');
title('Spectrogram: speech only');
xlabel('Time (s)');
ylabel('Frequency (Hz)');

%Listen results

fprintf('\nPlay 5 seconds of the Original Sound:');
audioplayer(x(1:5*Fe),Fe);
fprintf(' OK\n');
fprintf('Play 5 seconds of the new Sound: ');
audioplayer(output_signal(1:5*Fe),Fe);
fprintf('OK\n');
fprintf('Write denoised_speech.wav');
audiowrite('denoised_signal.wav',output_signal,Fe);