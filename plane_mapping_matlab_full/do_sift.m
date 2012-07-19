function [frames1 descr1] = do_sift(im1, thresh)
  
  addpath('sift');
  addpath('../');
  
  %fill in sift point correspondences
  % Convert images
  I1 = im2double(im1); if(size(I1,3)>1) I1 = rgb2gray(I1); end
  [I1_height I1_width] = size(I1);
  I1=I1-min(I1(:)) ;
  I1=I1/max(I1(:)) ;
  
  %fprintf('Computing frames and descriptors.\n') ;
  [frames1,descr1,gss1,dogss1] = sift( I1, 'Verbosity', 0, 'Threshold', thresh) ;
  descr1=uint8(512*descr1) ;
  
end
