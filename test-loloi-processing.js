const fs = require('fs');

// Simulate the processing logic for Loloi's CSV format
function processLoloiCsv() {
    console.log('Testing Loloi CSV processing...');
    
    // Read the CSV file
    const csvContent = fs.readFileSync('./loloi-test-file.csv', 'utf8');
    const lines = csvContent.split('\n').filter(line => line.trim());
    const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
    const dataRows = lines.slice(1).map(line => 
        line.split(',').map(cell => cell.trim().replace(/"/g, ''))
    );
    
    console.log('Headers:', headers);
    console.log('Total rows:', dataRows.length);
    
    // Test column mapping
    const getValue = (row, key) => {
        const foundKey = headers.find(h => h && h.toLowerCase() === key.toLowerCase());
        if (foundKey) {
            const dataIndex = headers.indexOf(foundKey);
            return row[dataIndex] || '';
        }
        return '';
    };
    
    // Process first 5 rows as a test
    const processedData = dataRows.slice(0, 5).map((row, index) => {
        const upc = String(getValue(row, 'UPC')).trim();
        if (!upc || upc === '') {
            console.warn(`Row ${index + 2}: Empty UPC, skipping`);
            return null;
        }
        
        // Handle quantity - try ATSQty first, then InStock
        let quantity = 0;
        const atsqty = getValue(row, 'ATSQty');
        const instock = getValue(row, 'InStock');
        
        if (atsqty && !isNaN(atsqty)) {
            quantity = parseInt(atsqty) || 0;
        } else if (instock) {
            if (instock.toLowerCase() === 'y' || instock.toLowerCase() === 'yes') {
                quantity = 1;
            } else {
                quantity = 0;
            }
        }
        
        // Process discontinued status
        const discontinued = String(getValue(row, 'Discontinued')).toLowerCase().trim();
        const isDiscontinued = discontinued === 'yes' || discontinued === '1' || discontinued === 'true' || discontinued === 'y';
        
        return {
            'Variant Barcode': upc,
            'Variant Inventory Qty': quantity,
            'Variant Metafield: custom.internal_discontinued [single_line_text_field]': isDiscontinued ? 'Yes' : 'No'
        };
    }).filter(item => item !== null);
    
    console.log('\nProcessed data (first 5 rows):');
    processedData.forEach((item, i) => {
        console.log(`Row ${i + 1}:`, item);
    });
    
    console.log(`\nSuccessfully processed ${processedData.length} rows`);
    
    return processedData;
}

// Run the test
processLoloiCsv();

