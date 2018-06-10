% You can remove the semi-colon at the end of each line to see the
% result of a computation in the repl.
example = "foo" % note: no semi-colon

sampling_rate = 32000;
first_stop_band = 200;
band_pass_start = 300;
band_pass_end = 500;
second_stop_band = 800;

ny = sampling_rate / 2; % nyquist freq of our sampling rate
Apass = abs(db(.98));   % maximum attenuation of passthrough frequencies
Astop1 = abs(db(.05));   % maximum passthrough in filtered frequencies
Astop2 = abs(db(.05));

% The first argument is the format that the rest of the arguments are
% passed in. This function builds a spec for how we want the filter to
% behave.
d = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',first_stop_band/ny,band_pass_start/ny,band_pass_end/ny,second_stop_band/ny,Astop1,Apass,Astop2)

% The following calls can allow you to inspect some explaination
% of what is going on but even better documentation may be found online.
%methods(d)
%help(d,'butter')

%%

% This function decides coefficients based on our design and the intended
% structure of the filter hear we use the butterworth method of deciding
% coefficients for a direct form 1 second-order sections filter 
biquad = design(d,'cheby1', 'FilterStructure','df1sos');

% This lets us plot the theoretical filtering capabilities of the filter
fvt = fvtool(biquad, 'Legend', 'on');
% Adding the next line allows displays the cummulative effect of sections 
fvt.SosviewSettings.View = 'Cumulative';

% These are the 'a' and 'b' coefficients where the 'b' coefficients have
% some scaling that we haven't talked about in class. 
sosMatrix = biquad.SOSMatrix
% Theses values are the scalars that we will use to convert to the
% the 'b' coefficients we talked of in class.
sclValues = biquad.ScaleValues;

% apply the scalars to 'b' and extract both 'a's and 'b's
b = repmat(sclValues(1:(end-1)),1,3) .* sosMatrix(:,(1:3))
a = sosMatrix(:,(5:6))

% transpose the coefficients
num = b' % matrix of scaled numerator sections
den = a' % matrix of denominator sections

% Uncomment this to automatically close windows as you are reruning
% the script
%close(fvt);


%% 

% double percent starts a new section that can be executed on it's own
% with ctrl + enter

% Make a Test Signal

samples_per_second = sampling_rate; % Hz
stop_time = 2.0; % s   % The lenght of the test signal
stop_freq = 2000; % Hz % The peak freaquency of the test signal

% the signal is an acending tone of stop_time lenghth in seconds
% t is a counter for each sample 0 ... 1 at 1/number of samples per second
% signal is the actual sampled signal
t = 0:1/samples_per_second:stop_time;
signal = chirp(t,0,stop_time,stop_freq);

% You can play it by uncommenting the following line
% Make sure you turn down the volume
% sound(signal, sampling_rate);
figure(2) % spectrogram clobers windows otherwise
% We can plot ffts over time with the following call
spectrogram(signal,512,16,1024,sampling_rate,'yaxis');

%%

% Test our filter's construction using Matlab's internal library

% Here is filtering our test signal with internal matlab libraries using
% floating point computation.
out1 = filter(biquad, signal);

figure(3)
% We can view the difference in spectrogram again
spectrogram(out1,512,16,1024,sampling_rate,'yaxis');
% Or use our biological frequency analysis tools
% sound(out1, sampling_rate);

%%

% Test our understanding of filtering by reconstructing the matlab 
% filtering code in floating point and comparing

% we zero-padd the signal so we can go backwards
% in time without special condition checks
% x[-2] -> x[0] and x[0] -> x[3]
% We'll fix this later
xs = cat(2,[0 0], signal);
ys = zeros(1, size(xs, 2));

% N Cascaded IIR Filters
for n = 1:size(num,2)
    
    % 1 IIR Filter Implimentation
    for i = 3:size(xs,2)

        ff = num(1,n) * xs(i) + ...
             num(2,n) * xs(i-1) + ...
             num(3,n) * xs(i-2);
        fb = den(1,n) * ys(i-1) + ...
             den(2,n) * ys(i-2);
        ys(i) = ff - fb;  
        
    end 
    
    % the output of the last IIR filter is the 
    % input for the next
    xs = ys;
    
end

% fix the zero-padding
ys = ys(3:end);

% Should be the same as matlab's filtering
figure(4)
spectrogram(ys,512,16,1024,sampling_rate,'yaxis');

%%
% If we are still unconvinced we can compare 10 samples at some internal
% point in the filtered signal (they are bit for bit the same)

ten_ys = ys(100:110)
ten_outs = out1(100:110)

%%

% Now we construct a filter in fixed point
% Note: we are "rolling our own" to demonstrate the overall technique
% but you are encouraged to find and use libraries to actually accomplish
% this. There may be cmsis libraries already in the particle firmware to
% do this.

%
%SWITCHING TO FIXED POINT
%

% Based on the type of data in signal we choose to represent it using
% 16 bit signed integers where the 16th bit is the sign bit, the 15th
% bit is the bit representing 1 and the lowest bit represents 1/(2^14)
% i.e. there are 14 bits for representing fractions of 1.
% 1.0 -> 0b' (+/-)100 0000 0000 0000
% Note that int16(2^17) doesn't overflow per se, it return the max int16
% this is matlab specific behavior that some fixnum libraries such as
% the cmsis dsp library should replicate.
% NOTE:  If you go beyond 14 bits here, you will need to change all the
% 'int16's below to 'int32's to prevent overflows.  
fixed_point_bits = 14

% Convert signal to fixpoint
signal2 = signal * 2^fixed_point_bits;
signal2 = int16( signal2);

% this is a smaller signal that we used for debugging our implementation
%signal2 = [ 0 2^14 0 0 0 0]

% convert coefficients to fixpoint 
num2 = int32( num * 2^fixed_point_bits)
den2 = int32( den * 2^fixed_point_bits)
%%

% we zero-padd the signal so we can go backwards
% in time without special condition checks
% x[-2] -> x[0] and x[0] -> x[3]
% We'll fix this later
xs2 = int16(cat(2,[0 0], signal2));
ys2 = int16(zeros(1, size(xs2, 2)));
size(xs2,2)
% N Cascaded IIR Filters
for n = 1:size(num2,2)   
    
    % 1 IIR Filter Implimentation
    for i = 3:size(xs2,2)
        
        % Just a reminder the direct form 1 formula is:
        % feed forward:
        % ff=(b0*xi + b1*xi_1 + b2*xi_2)
        % feed back:
        % fb = (a1*yi_1 + a2*yi_2)
        % combined:
        % yi = ff - fb
        
        % int32( v ) is a cast to an int32 type
        ff2 =       int32( num2(1,n)) * int32( xs2(i)   );
        ff2 = ff2 + int32( num2(2,n)) * int32( xs2(i-1) );
        ff2 = ff2 + int32( num2(3,n)) * int32( xs2(i-2) );
        fb2 =       int32( den2(1,n)) * int32( ys2(i-1) );
        fb2 = fb2 + int32( den2(2,n)) * int32( ys2(i-2) );
        
        % since everything just went through a multiply
        % we now have 28 bits of fraction representation
        % dividing by 2^14th shifts this back to 14 bits
        ys2(i) = int16( (ff2 - fb2) / 2^fixed_point_bits );  

    end 
    
    % the output of the last IIR filter is the 
    % input for the next
    xs2 = ys2;
end

% fix the zero-padding
ys2 = ys2(3:end);

%%

% If we convert back to floating point and run it through the spectrogram
% we nottice that we are pretty close to the filter behavior
ys2d = double(ys2);
ys2d = ys2d / 2^fixed_point_bits;

figure(5);

% Note that there is extra noise in the spectrogram but it is well
% under the level that we care about. Furthermore the actual signal
% is well filtered. Getting varying amounts of clarity can be achieved
% by tweaking the parameters of the filter and fixpoint implementation.
% Finding the right balance is somewhat of an art.
spectrogram(ys2d,512,16,1024,sampling_rate,'yaxis');
sound(ys2d, sampling_rate);