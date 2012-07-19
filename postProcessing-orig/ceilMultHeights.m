
th_a=0.8;
th_a2=0.8;

th_b=0.8;
th_b2=0.8;

th_c=0.8;
th_c2=0.8;

disp('Select the *.model file with ceilings. floors and walls. The walls will be adjusted (walls to touch each other at corners)');
disp('Press any key to continue...');

pause;

fillCorners2(th_a, th_a2);

disp('Select the *.model file just generated (with walls adjusted). File name should start with "F_"');
disp('Press any key to continue...');

pause;

removeCeilingsOrFloors(0);

disp('Removing ceilings from the file just genereated...');
disp('DONE');

disp('Select the *.model file with adjusted walls and removed ceilings. File name should start with "RC_F_"');
disp('Press any key to continue...');

pause;

fillCFWalls3b(th_b, th_b2);


disp('Select the *.model file just generated (with walls touching the floor). File name should start with "FCF_RC_F_"');
disp('Press any key to continue...');

pause;

removeCeilingsOrFloors(1);

disp('Removing floor from the file just genereated...');
disp('DONE');

disp('Select the *.model file with adjusted walls and removed floor. File name should start with "RF_FCF_RC_F_"');
disp('Then select the *.model file with the ceilings. File name should start with "CEILINGS_"');
disp('Press any key to continue...');

pause;

mergeModels();

disp('Merging walls with ceilings...');
disp('DONE..');

disp('Select the *.model file with adjusted walls and ceilings. File name should start with "FINAL_RF_FCF_RC_F_"');


fillCFWalls3c(th_c, th_c2);

disp('First select the *.model file just generated (with walls touching the ceilings). File name should start with "FCF_FINAL_RF_FCF_RC_F_"');
disp('Then select the *.model file with the adjusted floor. File name should start with "FLOORS_"');
disp('Press any key to continue...');

pause;

mergeModels();

disp('Putting together all planes...Final model file name should start with" FINAL_"');
disp('DONE');



