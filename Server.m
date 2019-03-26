clc, clear all;

%% Reading the original image to calculate mean average error
I = imread('Sampleimage.tif');

%%
tcpipServer = tcpip('0.0.0.0', 30000, 'NetworkRole', 'Server');
set(tcpipServer,'InputBufferSize',300000);
set(tcpipServer,'Timeout',5); %Waiting time in seconds to complete read and write operations
fopen(tcpipServer);
get(tcpipServer, 'BytesAvailable');


tcpipServer.BytesAvailable; 
DataReceived =[];
 pause(0.1);
while (get(tcpipServer, 'BytesAvailable') > 0) 
    
    tcpipServer.BytesAvailable;
    rawData = fread(tcpipServer,300000/8,'double');
    DataReceived = [DataReceived; rawData];
    pause(0.1)
    size(rawData,1) 
    %disp(tcpipServer.BytesAvailable)
    %disp(tcpipServer)
end
fclose(tcpipServer)
delete(tcpipServer); 
clear tcpipServer 

[h,w,c] = size(DataReceived);
new = reshape(DataReceived,[h/2,2]);

im = new(:, 1);  
im = im.';
in = new(:, 2);
in=in.';

%% Process Run-length-deconding function on the received image
Immmmm=rl_dec(im, in);

%% Process iZigzag function on the decoded image
Image5 = invzigzag(Immmmm,256, 256);
Image5 = reshape(Image5,256,256,1);

%% Process idct function on the quantized image
T = dctmtx(8);
invdct = @(block_struct) T' * block_struct.data * T;

%% Process idct on the image, block-by-block (8*8)
I2 = blockproc(Image5,[8 8],invdct);

%% Shoiwng original Image
figure(1)
imshow(I)
title('Original Image')
%% Showing output Image
figure(2)
imshow(I2)
title('Received image')

%% Getting the double value of input and output image
Input = double(I);
Output = double(I2);

%% Calculate mean-squared error between the two images.
err = immse(Input, Output);
fprintf('\n The mean-squared error %0.4f\n', err)

%% iZigzag function
function out=invzigzag(in,num_rows,num_cols)
tot_elem=length(in);
if nargin>3
	error('Too many input arguments');
elseif nargin<3
	error('Too few input arguments');
end
% Check if matrix dimensions correspond
if tot_elem~=num_rows*num_cols
	error('Matrix dimensions do not coincide');
end
% Initialise the output matrix
out=zeros(num_rows,num_cols);
cur_row=1;	cur_col=1;	cur_index=1;
% First element
%out(1,1)=in(1);
while cur_index<=tot_elem
	if cur_row==1 & mod(cur_row+cur_col,2)==0 & cur_col~=num_cols
		out(cur_row,cur_col)=in(cur_index);
		cur_col=cur_col+1;							%move right at the top
		cur_index=cur_index+1;
		
	elseif cur_row==num_rows & mod(cur_row+cur_col,2)~=0 & cur_col~=num_cols
		out(cur_row,cur_col)=in(cur_index);
		cur_col=cur_col+1;							%move right at the bottom
		cur_index=cur_index+1;
		
	elseif cur_col==1 & mod(cur_row+cur_col,2)~=0 & cur_row~=num_rows
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row+1;							%move down at the left
		cur_index=cur_index+1;
		
	elseif cur_col==num_cols & mod(cur_row+cur_col,2)==0 & cur_row~=num_rows
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row+1;							%move down at the right
		cur_index=cur_index+1;
		
	elseif cur_col~=1 & cur_row~=num_rows & mod(cur_row+cur_col,2)~=0
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row+1;		cur_col=cur_col-1;	%move diagonally left down
		cur_index=cur_index+1;
		
	elseif cur_row~=1 & cur_col~=num_cols & mod(cur_row+cur_col,2)==0
		out(cur_row,cur_col)=in(cur_index);
		cur_row=cur_row-1;		cur_col=cur_col+1;	%move diagonally right up
		cur_index=cur_index+1;
		
	elseif cur_index==tot_elem						%input the bottom right element
        out(end)=in(end);							%end of the operation
		break										%terminate the operation
    end
end
end
%% Run-length-decoding Function
function x=rl_dec(d,c);
% This function performs Run Length Dencoding to the elements of the strem 
% of data d according to their number of apperance given in c. There is no 
% restriction on the format of the elements of d, while the elements of c 
% must all be integers.
% This function is built by Abdulrahman Ikram Siddiq in Oct-1st-2011 5:36pm.
 
if nargin<2
    error('not enough number of inputs')
end
x=[];
for i=1:length(d)
x=[x d(i)*ones(1,c(i))];
end
end