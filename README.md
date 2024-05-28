# Analyzing-the-Impact-of-Business-Hour-Mismatch-on-Order-Volume-in-the-Food-Delivery-Industry
The goal of this Project is to come up with a query to understand differences in the business hours for a store across all platforms. You will compute a metric called business hour mismatch between a store on Grubhub and a store on UberEats

We wrote an SQL query which Computes Business Hours Mismatch between a restaurant on two platforms. For the sake of simplicity, we will assume UberEats as the ground truth. We then tried to find the issues in Grubhub store hours. 

Note all the data is sample data available in BigQuery. (To view the data, open your personal BigQuery console and run these queries).
UberEats
SELECT * FROM arboreal-vision-339901.take_home_v2.virtual_kitchen_ubereats_hours LIMIT 1000;
Grubhub
SELECT * FROM arboreal-vision-339901.take_home_v2.virtual_kitchen_grubhub_hours LIMIT 1000;

The output would come in the form of 
![image](https://github.com/mishra169/Analyzing-the-Impact-of-Business-Hour-Mismatch-on-Order-Volume-in-the-Food-Delivery-Industry/assets/104723673/5fd36d35-1d1b-4de2-886f-241c8c27969a)

The above file contain the SQL queries in JSON format.


