function angle = rectify_image(im)

  % Figure out the angle that we should rotate by
  % in order to have vertical lines
  imbw = rgb2gray(im);
  imbw = imrotate(imbw,-90);
  h = fspecial('gaussian', 9, 4);
  imbw = imfilter(imbw, h, 'replicate');
  BW = edge(imbw,'canny');
  [H, T, R] = hough(BW, 'RhoResolution', 0.5, 'Theta', -10:0.1:10);
  P = houghpeaks(H,1);
  angle = T(P(2));

end
