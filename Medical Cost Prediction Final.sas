/* Import the dataset into the bigdata library */
PROC IMPORT DATAFILE="/home/u64077712/New Folder/insurance.csv"
    OUT=bigdata.medical_data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* Inspect the dataset structure */
PROC CONTENTS DATA=bigdata.medical_data;
RUN;

/* Display the first 10 rows */
PROC PRINT DATA=bigdata.medical_data (OBS=10);
RUN;

/* Data Preprocessing */
/* Check for missing values */
PROC MEANS DATA=bigdata.medical_data NMISS N;
RUN;

/* Encode categorical variables: sex, smoker, region */
DATA bigdata.medical_data_clean;
    SET bigdata.medical_data;
    IF sex = 'male' THEN sex_encoded = 1; ELSE sex_encoded = 0;
    IF smoker = 'yes' THEN smoker_encoded = 1; ELSE smoker_encoded = 0;

    /* Encode region using dummy variables */
    IF region = 'northeast' THEN region_ne = 1; ELSE region_ne = 0;
    IF region = 'northwest' THEN region_nw = 1; ELSE region_nw = 0;
    IF region = 'southeast' THEN region_se = 1; ELSE region_se = 0;
    IF region = 'southwest' THEN region_sw = 1; ELSE region_sw = 0;
RUN;

/* Verify encoded variables */
PROC PRINT DATA=bigdata.medical_data_clean (OBS=10);
RUN;

/* Normalize Numerical Variables */
/* Normalize age, bmi, and children */
PROC STANDARD DATA=bigdata.medical_data_clean OUT=bigdata.medical_data_normalized MEAN=0 STD=1;
    VAR age bmi children;
RUN;

/* Verify normalization */
PROC MEANS DATA=bigdata.medical_data_normalized;
    VAR age bmi children;
RUN;

/* Data Analysis */
/* Step 1: Feature Distributions */
/* Distribution of Age */
PROC SGPLOT DATA=bigdata.medical_data_clean;
    HISTOGRAM age / BINWIDTH=5;
    TITLE "Distribution of Age";
    XAXIS LABEL="Age";
    YAXIS LABEL="Frequency";
RUN;

/* Distribution of BMI */
PROC SGPLOT DATA=bigdata.medical_data_clean;
    HISTOGRAM bmi / BINWIDTH=2;
    TITLE "Distribution of BMI";
    XAXIS LABEL="BMI";
    YAXIS LABEL="Frequency";
RUN;

/* Distribution of Charges */
PROC SGPLOT DATA=bigdata.medical_data_normalized;
    HISTOGRAM charges / BINWIDTH=1000;
    DENSITY charges / TYPE=NORMAL;
    TITLE "Distribution of Medical Charges";
    XAXIS LABEL="Charges";
    YAXIS LABEL="Frequency";
RUN;

/* Step 2: Correlations */
/* Correlation Matrix */
PROC CORR DATA=bigdata.medical_data_clean;
    VAR age bmi children charges;
RUN;


/* Split data into training (80%) and testing (20%) */
PROC SURVEYSELECT DATA=bigdata.medical_data_normalized OUT=bigdata.medical_split
    SAMPRATE=0.8 SEED=12345 OUTALL;
RUN;

/* Create training and testing datasets */
DATA bigdata.training_data bigdata.testing_data;
    SET bigdata.medical_split;
    IF selected = 1 THEN OUTPUT bigdata.training_data;
    ELSE OUTPUT bigdata.testing_data;
RUN;

/* Train the regression model on training data */
PROC REG DATA=bigdata.training_data;
    MODEL charges = age sex_encoded bmi children smoker_encoded region_ne region_nw region_se region_sw;
    OUTPUT OUT=bigdata.training_results P=Predicted_Charges;
RUN;

/*Calculate Metrics*/
/* Merge predicted values with actual values in testing data */
PROC REG DATA=bigdata.testing_data OUTEST=bigdata.regression_metrics;
    MODEL charges = age sex_encoded bmi children smoker_encoded region_ne region_nw region_se region_sw;
    OUTPUT OUT=bigdata.testing_results P=Predicted_Charges;
RUN;

/* Calculate evaluation metrics */
PROC MEANS DATA=bigdata.testing_results;
    VAR charges Predicted_Charges;
    OUTPUT OUT=bigdata.metrics_results 
        MEAN=Mean_Actual Mean_Predicted
        STD=Std_Actual Std_Predicted;
RUN;

/* Histogram of medical charges */
PROC SGPLOT DATA=bigdata.medical_data_normalized;
    HISTOGRAM charges / BINWIDTH=1000;
    DENSITY charges / TYPE=NORMAL;
    TITLE "Distribution of Medical Charges";
    XAXIS LABEL="Charges";
    YAXIS LABEL="Frequency";
RUN;

/* Scatter plot of BMI vs. Charges */
PROC SGPLOT DATA=bigdata.medical_data_normalized;
    SCATTER X=bmi Y=charges / GROUP=smoker_encoded;
    REG X=bmi Y=charges / GROUP=smoker_encoded LINEATTRS=(PATTERN=SOLID);
    TITLE "Relationship Between BMI and Charges";
    XAXIS LABEL="BMI";
    YAXIS LABEL="Charges";
RUN;

/* Box plot of charges by smoker status */
PROC SGPLOT DATA=bigdata.medical_data_clean;
    VBOX charges / CATEGORY=smoker_encoded;
    TITLE "Impact of Smoking on Medical Charges";
    XAXIS LABEL="Smoker (0=No, 1=Yes)";
    YAXIS LABEL="Charges";
RUN;

/* Visualize actual vs. predicted charges */
PROC SGPLOT DATA=bigdata.testing_results;
    SCATTER X=charges Y=Predicted_Charges / MARKERATTRS=(SIZE=10);
    XAXIS LABEL="Actual Charges";
    YAXIS LABEL="Predicted Charges";
    TITLE "Actual vs. Predicted Medical Charges";
RUN;


/* Save the cleaned dataset */
PROC EXPORT DATA=bigdata.medical_data_clean
    OUTFILE="/home/u64077712/New Folder/cleaned_medical_data.csv"
    DBMS=CSV
    REPLACE;
RUN;

/* Export the training and testing results */
PROC EXPORT DATA=bigdata.training_results
    OUTFILE="/home/u64077712/New Folder/training_results.csv"
    DBMS=CSV
    REPLACE;
RUN;

PROC EXPORT DATA=bigdata.testing_results
    OUTFILE="/home/u64077712/New Folder/testing_results.csv"
    DBMS=CSV
    REPLACE;
RUN;