# Setup guide: Olist sales analysis

Follow these steps once. Total time: about 45 minutes.

## 1. Install PostgreSQL and pgAdmin

1. Go to <https://www.postgresql.org/download/>, choose your operating system and download the installer from EDB. Any version from 15 upwards works.
2. Run the installer and keep the default components (PostgreSQL Server, pgAdmin 4, Command Line Tools). Stack Builder is not needed.
3. Set a password for the `postgres` user and **write it down**. Keep the default port, 5432.
4. On a Mac, the same installer works. Postgres.app is an alternative.

## 2. Get the data

1. Create a free Kaggle account and open <https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce>.
2. Click **Download** and unzip the file into this project's `data/raw/` folder.
3. Check that `data/raw/` holds these nine files:
   - `olist_customers_dataset.csv`
   - `olist_geolocation_dataset.csv`
   - `olist_order_items_dataset.csv`
   - `olist_order_payments_dataset.csv`
   - `olist_order_reviews_dataset.csv`
   - `olist_orders_dataset.csv`
   - `olist_products_dataset.csv`
   - `olist_sellers_dataset.csv`
   - `product_category_name_translation.csv`

## 3. Create the database

1. Open pgAdmin and enter the password from step 1.
2. In the left panel, open **Servers > PostgreSQL**, right-click **Databases** and choose **Create > Database**. Name it `olist` and save.

## 4. Create the tables

1. Right-click the `olist` database and choose **Query Tool**.
2. Open `sql/00_create_schema.sql` with the folder icon and press **F5** to run it.
3. Refresh **olist > Schemas > public > Tables**. You should see nine tables.

## 5. Load the data

1. Right-click the `olist` database and choose **PSQL Tool**. A terminal opens.
2. Type these two lines, replacing the path with where this project sits. Use forward slashes, even on Windows.

   ```
   \cd 'C:/Users/Peter/olist-sales-analysis/data/raw'
   \i 'C:/Users/Peter/olist-sales-analysis/sql/01_load_data.sql'
   ```

3. Each table prints a `COPY` line with its row count. The geolocation file has about a million rows, so it takes a little longer.

## 6. Check the data

1. In the Query Tool, open `sql/02_data_checks.sql`.
2. Run the checks one at a time: highlight a query and press **F5**.
3. Compare the row counts with the expected numbers in the file's first comment.
4. Write down what each check shows in `notes/data_quality.md`. These quirks shape your analysis and come up in interviews.

## 7. Answer the four questions

Work through `sql/10_q1_...` to `sql/13_q4_...` in order. Each file states the question, the decisions to make first, the output columns and hints. Write your query under each part and save the file.

When a query works, export its result to `results/` (Query Tool: the **Save results to file** icon above the results grid). Name the files after the question, for example `q1a_monthly_revenue.csv`.

## 8. Make the charts

1. Install Python 3 from <https://www.python.org/downloads/>.
2. In a terminal opened in this folder, run `pip install -r requirements.txt`.
3. Edit the bottom of `charts/make_charts.py` to point at your result files, then run `python charts/make_charts.py`. The PNGs land in `charts/`.

## 9. Publish on GitHub

1. Create a free GitHub account and a new public repository called `olist-sales-analysis`.
2. Install GitHub Desktop (<https://desktop.github.com>) if you prefer not to use the command line.
3. Add this folder, commit and push. The `.gitignore` file keeps the raw CSVs out of the repository, which keeps it small; anyone can download them from Kaggle.
4. Fill in `README.md` last, once the findings and charts are ready.
