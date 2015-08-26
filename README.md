# Audio-Denoising
A Comparison between Spectral Subtraction and Notch Filtering for Audio Signal Denoising
#Spectral Subtraction
One of the most popular methods of reducing the effect of background (additive) noise is Spectral Subtraction. The background noise is the most common factor degrading the quality and intelligibility of speech in recordings. This de-noising algorithm intends to lower the noise level without affecting the speech signal quality. 
#Paramentric Filters
We need to design notch parametric equalizers that will selectively filter out the frequencies at which noise occurs.Since the notch filters may also remove components of the speech signal at the above frequencies, we will apply a peak filter to boost the speech signal at the output of the notch filters.

Implemented on Matlab. Generates and Plays Denoised Signal on execution
