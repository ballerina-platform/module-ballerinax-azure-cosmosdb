class DatabaseIterator {

    private stream<Database> st;
    private int count;
    private Headers headers;

    isolated function init(stream<Database> st,int count,Headers headers) {
        self.st = st;
        self.count = count;
        self.headers = headers;
    }

    public isolated function getStream() returns stream<Database> {
        return self.st;
    }

    public isolated function getHeaders() returns Headers {
        return self.headers;
    }

    public isolated function getCount() returns int {
        return self.count;
    }
}
