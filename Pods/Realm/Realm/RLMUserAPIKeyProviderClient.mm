////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMUserAPIKeyProviderClient.h"

#import "RLMApp_Private.hpp"
#import "RLMUserAPIKey_Private.hpp"
#import "RLMObjectId_Private.hpp"

@implementation RLMUserAPIKeyProviderClient

- (realm::app::App::UserAPIKeyProviderClient)client {
    return self.app._realmApp->provider_client<realm::app::App::UserAPIKeyProviderClient>();
}

- (std::shared_ptr<realm::SyncUser>)currentUser {
    return self.app._realmApp->current_user();
}

- (void)createApiKeyWithName:(NSString *)name
                  completion:(RLMOptionalUserAPIKeyBlock)completion {
    
    self.client.create_api_key(name.UTF8String, self.currentUser,
                               ^(realm::util::Optional<realm::app::App::UserAPIKey> userAPIKey,
                                 realm::util::Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        
        if (userAPIKey) {
            return completion([[RLMUserAPIKey alloc] initWithUserAPIKey:userAPIKey.value()], nil);
        }
        
        return completion(nil, nil);
    });
}

- (void)fetchApiKey:(RLMObjectId *)objectId
         completion:(RLMOptionalUserAPIKeyBlock)completion {
    self.client.fetch_api_key(objectId.value,
                              self.currentUser,
                              ^(realm::util::Optional<realm::app::App::UserAPIKey> userAPIKey,
                                realm::util::Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        
        if (userAPIKey) {
            return completion([[RLMUserAPIKey alloc] initWithUserAPIKey:userAPIKey.value()], nil);
        }
        
        return completion(nil, nil);
    });
}

- (void)fetchApiKeysWithCompletion:(RLMUserAPIKeysBlock)completion {
    self.client.fetch_api_keys(self.currentUser,
                               ^(const std::vector<realm::app::App::UserAPIKey>& userAPIKeys,
                                 realm::util::Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        
        NSMutableArray *apiKeys = [[NSMutableArray alloc] init];
        for(auto &userAPIKey : userAPIKeys) {
            [apiKeys addObject:[[RLMUserAPIKey alloc] initWithUserAPIKey:userAPIKey]];
        }
        
        return completion(apiKeys, nil);
    });
}

- (void)deleteApiKey:(RLMObjectId *)objectId
          completion:(RLMUserAPIKeyProviderClientOptionalErrorBlock)completion {
    self.client.delete_api_key(objectId.value,
                               self.currentUser,
                               ^(realm::util::Optional<realm::app::AppError> error) {
        [self.app handleResponse:error completion:completion];
    });
}

- (void)enableApiKey:(RLMObjectId *)objectId
          completion:(RLMUserAPIKeyProviderClientOptionalErrorBlock)completion {
    self.client.enable_api_key(objectId.value,
                               self.currentUser,
                               ^(realm::util::Optional<realm::app::AppError> error) {
        [self.app handleResponse:error completion:completion];
    });
}

- (void)disableApiKey:(RLMObjectId *)objectId
           completion:(RLMUserAPIKeyProviderClientOptionalErrorBlock)completion {
    self.client.disable_api_key(objectId.value,
                                self.currentUser,
                                ^(realm::util::Optional<realm::app::AppError> error) {
        [self.app handleResponse:error completion:completion];
    });
}

@end
