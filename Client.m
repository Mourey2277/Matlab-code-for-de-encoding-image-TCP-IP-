clear; clc;
%% Reading the image
I = imread('SampleImage.tif');
I = im2double(I);

%% Create block processing function with dct method.
T = dctmtx(8);
dct = @(block_struct) T * block_struct.data * T';

%% Process dct on the image, block-by-block (8*8)
B = blockproc(I,[8 8],dct);

%% Create mask for Quantization method L={1..8}.
mask = zeros(8,8);
L=1;
mask(1:L,1:L) = 1;

%% Process Quantization on the image, block-by-block (8*8)  
B2 = blockproc(B,[8 8],@(block_struct) mask .* block_struct.data);

%% Process Zigzag function on the quantized image
Image4 = zigzag(B2);

%% %% Process Run-length-encoding function on the quantized image 
[im in]=my_RLE(Image4);

%% Sending the data server
send=[im in];
data = send(:);
size(data);

%% Extracting the data's details to know the buffer size
s = whos('data')
s.size;
s.bytes;

%% Creating the TCP connecting for the Client
tcpipClient = tcpip('localhost', 30000, 'NetworkRole', 'client');
set(tcpipClient, 'OutputBufferSize', s.bytes);
fopen(tcpipClient);
    fwrite(tcpipClient, data(:), 'double');
fclose(tcpipClient);

%% Zigzag Function
function output = zigzag(in)
h = 1;
v = 1;
vmin = 1;
hmin = 1;
vmax = size(in, 1);
hmax = size(in, 2);
i = 1;
output = zeros(1, vmax * hmax);
%----------------------------------
while ((v <= vmax) && (h <= hmax))
    
    if (mod(h + v, 2) == 0)                 % going up
        if (v == vmin)       
            output(i) = in(v, h);        % if we got to the first line
            if (h == hmax)
	      v = v + 1;
	    else
              h = h + 1;
            end
            i = i + 1;
        elseif ((h == hmax) && (v < vmax))   % if we got to the last column
            output(i) = in(v, h);
            v = v + 1;
            i = i + 1;
        elseif ((v > vmin) && (h < hmax))    % all other cases
            output(i) = in(v, h);
            v = v - 1;
            h = h + 1;
            i = i + 1;
        end
        
    else                                    % going down
       if ((v == vmax) && (h <= hmax))       % if we got to the last line
            output(i) = in(v, h);
            h = h + 1;
            i = i + 1;
        
       elseif (h == hmin)                   % if we got to the first column
            output(i) = in(v, h);
            if (v == vmax)
	      h = h + 1;
	    else
              v = v + 1;
            end
            i = i + 1;
       elseif ((v < vmax) && (h > hmin))     % all other cases
            output(i) = in(v, h);
            v = v + 1;
            h = h - 1;
            i = i + 1;
       end
    end
    if ((v == vmax) && (h == hmax))          % bottom right element
        output(i) = in(v, h);
        break
    end
end
end
%% Run-length-encoding Function
function [d,c]=my_RLE(x)
% This function performs Run Length Encoding to a strem of data x. 
% [d,c]=rl_enc(x) returns the element values in d and their number of
% apperance in c. All number formats are accepted for the elements of x.
% This function is built by Abdulrahman Ikram Siddiq in Oct-1st-2011 5:15pm.
if nargin~=1
    error('A single 1-D stream must be used as an input')
end
ind=1;
d(ind)=x(1);
c(ind)=1;
for i=2 :length(x)
    if x(i-1)==x(i)
       c(ind)=c(ind)+1;
    else ind=ind+1;
         d(ind)=x(i);
         c(ind)=1;
    end
end
end