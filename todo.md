- The next improvement I'd make is DatabaseManagementRepository.exportTransactionsCsv().

Right now it first creates a temporary CSV in the app's private storage and then exports it. We can redesign it so the CSV is streamed directly to the export destination (desktop or SAF), eliminating the temporary file and making the export architecture cleaner.


