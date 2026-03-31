// Datasource provider declarations for dependency injection.
//
// Used by use case providers and repository implementations.
// Presentation layer should import datasource providers from here
// when needed for use case construction, never directly from
// data/datasources/ files.

export 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
export 'package:fishfeed/data/datasources/remote/api_client.dart'
    show apiClientProvider;
