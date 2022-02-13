import pandas as pd

with open('orders_dimen', 'r') as source:
    with open('some_other_file', 'w') as result:
        writer = csv.writer(result, lineterminator='\n')
        reader = csv.reader(source)
        source.readline()
        for row in reader:
            ts = row[17]
            ts = datetime.strptime(ts, '%Y-%m-%dT%H:%MZ').strftime("%m/%d/%Y")
            if ts != "":
                writer.writerow(row)
source.close()
result.close()