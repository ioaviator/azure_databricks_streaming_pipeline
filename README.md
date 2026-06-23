
## Weather-Streams Analytics Pipeline on Azure

  ## Introduction
Weather-Streams Analytics Pipeline on Azure is a Terraform-managed, cloud-based data engineering project that simulates a real-time weather data streaming and process it through Azure.

The pipeline uses a Python producer to generate synthetic weather events for multiple global cities, including temperature, humidity, wind speed, pressure, precipitation, cloud cover, and weather conditions. 

These events are streamed into Azure Event Hub, ingested and transformed using Azure Databricks, and stored in Azure Data Lake Storage using the Bronze, Silver, and Gold medallion architecture pattern.

This project demonstrates how to build an analytics-ready streaming data pipeline on Azure using infrastructure as code, key vault secret management, and monitoring.


  # Data Pipeline Architecture
  ![data pipeline](./img/databricks_event_hubs_stream.gif)

<br>

## Problem Statement

Applications often generate continuous streams of data that need to be ingested, processed, stored, and made available for analytics. Weather data is a good example of this type of streaming data because conditions such as temperature, humidity, wind speed, precipitation, and pressure can change frequently across different locations.

The challenge is to design a data pipeline that can handle continuous event ingestion, process raw data into clean and structured formats, and organize the output for analytics. This project addresses that challenge by building a synthetic real-time weather data pipeline using Azure Event Hub, Azure Databricks, and Azure Data Lake Storage using the Medallion Architecture pattern.

## Business Context

Weather data is valuable for industries such as logistics, transportation, agriculture, aviation, and travel. These industries depend on timely weather insights to support operational planning, risk management, demand forecasting, and decision-making.

For example, logistics companies can use weather data to adjust delivery routes, agriculture businesses can monitor climate conditions for crop planning, and travel companies can improve customer experience by responding to changing weather conditions.

This project demonstrates how an organization can build a cloud-based data pipeline that converts raw streaming weather events into cleaned and analytics-ready datasets for reporting, dashboards, and downstream business intelligence use cases.

## Objectives

The main objectives of this project are:

- Build an analytics data streaming pipeline on Azure
- Generate synthetic weather data using a Python-based producer application
- Stream weather events into Azure Event Hub 
- Process incoming weather data using Azure Databricks and PySpark
- Store raw, cleaned, and analytics-ready data using the Bronze, Silver, and Gold medallion architecture
- Manage cloud infrastructure with Terraform
- Secure credentials and connection strings using Azure Key Vault
- Monitor metrics and logs using Azure Monitor
- Prepare transformed weather data for downstream analytics, reporting, and dashboard

## Tech Stack

| Tool / Service | Purpose |
|---|---|
| Python | Generates synthetic real-time weather data for multiple global cities |
| Azure Event Hub | Acts as the real-time event streaming and ingestion service |
| Azure Databricks | Processes streaming data and performs transformations across the Bronze, Silver, and Gold layers |
| PySpark | Used in Databricks for distributed data processing and transformation |
| Azure Data Lake Storage Gen2 | Stores weather data in the Medallion Architecture layers |
| Delta Lake | Provides reliable storage, ACID transactions, and scalable lakehouse table management |
| Terraform | Provisions and manages Azure infrastructure using Infrastructure as Code |
| Azure Key Vault | Stores secrets such as connection strings, access keys, and credentials securely |
| Azure Monitor | Monitors pipeline health, resource performance, and operational metrics |
| Azure Cloud Platform | Provides the cloud infrastructure for hosting and managing the full data pipeline |

## Setup Instructions

  ## Clone the repository
  ```bash
    git clone https://github.com/ioaviator/Weather-Streams-Analytics-Pipeline-on-Azure.git
  ```
Open the project directory with your editor of choice (VsCode preferred).  On the terminal, run the following commands
<br>

  ## Create and activate the project virtual environment (Windows OS Version)
  ```bash
    python -m venv venv

    source venv/Scripts/activate
  ```

  ## Install the libraries
  ```bash
    pip install -r requirements.txt
  ```
  
  ## Setup and create Azure cloud resources
  - #### Login to Azure cloud using the Azure (az cli) command
  - #### Select your subscription from the options. (Authentication Done)
```bash
  az login
```
  - #### Navigate to the terraform folder, initialize terraform provider configurations and create resources
  
```bash
  cd terraform

  terraform init

  terraform plan (Optional)

  terraform apply -auto-approve
```

  ## Databricks Notebook Setup
  - #### Login to the Azure databricks workspace, from the resource group created in Azure portal
  - #### Create a folder using a name of your choice, from the workspace/Users directory and import `stream_data_processor.ipynb` from the local workspace directory, into the created folder in databricks
  - #### Click and open the ipynb file into the jupyter notebook workspace
  - #### Select your created cluster, from the top right. Click on `Run all`

    ![Azure Workspace](./img/azure_workspace.png)
    
    <br>

    ![workspace import notebook](./img/azure_workspace_import_notebook.png)

    <br>

    ![ipynb jupyter notebook](./img/ipynb_jupyter_env.png)

  ## Python: Stream data into Event Hubs
  - #### Navigate into the workspace directory, run the .py script to initiate streaming process
  
```bash
  cd workspace

  python data_stream_events.py
```

- #### Check the Azure databricks workspace environment to confirm incoming data
  ![incoming data](./img/incoming_data_stream_bronze.png)

- #### Create a new notebook and run the queries below, to confirm pyspark data processing
  ![bronze data](./img/sql_query_sample_data_bronze.png)

  <br>

  ![silver data](./img/incoming_data_stream_silver.png)

  <br>

  ![gold data](./img/analytics_ready_data_streams_gold.png)

- #### Once confirmed, click on the interrupt icon on the top right in databricks workspace to stop cluster from running
  
  ## Visualization with Power BI
  - #### Click on the the marketplace option, search and select Power BI Desktop. Click on Connect
  ![power bi connector](./img/visuals_power_bi.png)

  - #### Select your cluster from the compute option, click on `download connection file`
  - #### Locate the downloaded file from your local environment, `double click to open it with Power BI`
  
  ![power bi databricks auth](./img/power_bi_databricks_auth_connection.png)

  <br>

  - #### Select `Azure Active Directory`, click on `sign in`. Login with Azure credentials. Click on `Connect`
  - #### From the navigator pane, select the data from the `gold` folder, click on load
  - #### You can now visualize the weather streams data using Power BI.
  
  ![power bi databricks data connection](./img/power_bi_data_connection_result.png)

  ## Destroy resources
  - #### Run the command from the terraform directory path
  ```bash
    terraform destroy -auto-approve
  ```
