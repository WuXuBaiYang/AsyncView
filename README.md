# async_view

## Usage
    AsyncView<String>(
      initialData: "Initial Result",
      builder: (context, result) {
        ///main view builder
        return Text("show result:$result");
      },
      retryChildBuilder: (context) {
        ///retry button child view
        return Text("Retry Button child");
      },
      loadingBuilder: (context) {
        ///loading view
        return Center(child: CircularProgressIndicator());
      },
      future: (context) async {
        ///async function
        await Future.delayed(Duration(milliseconds: 100));
        return "test result";
      },
    );
