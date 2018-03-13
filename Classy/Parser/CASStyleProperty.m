//
//  CASStyleProperty.m
//  Classy
//
//  Created by Jonas Budelmann on 25/09/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CASStyleProperty.h"
#import "NSString+CASAdditions.h"
#import "UIImage+CASAdditions.h"
#import "CASExpressionSolver.h"

@interface CASStyleProperty ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSArray *values;

@property (nonatomic, strong, readwrite) CASToken *nameToken;
@property (nonatomic, strong, readwrite) NSArray *valueTokens;
@end

@implementation CASStyleProperty {
    NSMutableArray *_childStyleProperties;
}

@synthesize childStyleProperties = _childStyleProperties;

- (id)initWithNameToken:(CASToken *)nameToken valueTokens:(NSArray *)valueTokens {
    self = [super init];
    if (!self) return nil;

    self.nameToken = nameToken;
    self.valueTokens = valueTokens;

    return self;
}

#pragma mark - properties

- (NSString *)name {
    if (!_name) {
        _name = [self.nameToken.value cas_stringByCamelCasing];
    }
    return _name;
}

- (NSArray *)values {
    if (!_values) {
        NSMutableArray *values = NSMutableArray.new;
        for (CASToken *valueToken in self.valueTokens) {
            if (valueToken.value) {
                [values addObject:valueToken.value];
            }
        }
        _values = values;
    }
    return _values;
}

#pragma mark - helpers

- (id)valueOfTokenType:(CASTokenType)tokenType {
    for (CASToken *token in self.valueTokens) {
        if (token.type == tokenType) return token.value;
    }
    return nil;
}

- (NSArray *)consecutiveValuesOfTokenType:(CASTokenType)tokenType {
    NSMutableArray *tokens = NSMutableArray.new;
    for (CASToken *token in self.valueTokens) {
        if (token.type == tokenType) {
            [tokens addObject:token.value];
        } else if (tokens.count && !token.isWhitespace && ![token valueIsEqualTo:@","]) {
            return tokens;
        }
    }
    return tokens;
}

#pragma - value transformation

- (BOOL)transformValuesToCGSize:(CGSize *)size {
    NSArray *unitTokens = [self consecutiveValuesOfTokenType:CASTokenTypeUnit];
    if (unitTokens.count == 1) {
        CGFloat value = [unitTokens[0] doubleValue];
        *size = CGSizeMake(value, value);
        return YES;
    }
    if (unitTokens.count == 2) {
        CGFloat value1 = [unitTokens[0] doubleValue];
        CGFloat value2 = [unitTokens[1] doubleValue];
        *size = CGSizeMake(value1, value2);
        return YES;
    }
    return NO;
}

- (BOOL)transformValuesToCGPoint:(CGPoint *)point {
    NSArray *unitTokens = [self consecutiveValuesOfTokenType:CASTokenTypeUnit];
    if (unitTokens.count == 1) {
        CGFloat value = [unitTokens[0] doubleValue];
        *point = CGPointMake(value, value);
        return YES;
    }
    if (unitTokens.count == 2) {
        CGFloat value1 = [unitTokens[0] doubleValue];
        CGFloat value2 = [unitTokens[1] doubleValue];
        *point = CGPointMake(value1, value2);
        return YES;
    }
    return NO;
}

- (BOOL)transformValuesToCGRect:(CGRect *)rect {
    NSArray *unitTokens = [self consecutiveValuesOfTokenType:CASTokenTypeUnit];
    if (unitTokens.count == 4) {
        *rect = CGRectMake([unitTokens[0] doubleValue], [unitTokens[1] doubleValue], [unitTokens[2] doubleValue], [unitTokens[3] doubleValue]);
        return YES;
    }
    return NO;
}

- (BOOL)transformValuesToUIEdgeInsets:(UIEdgeInsets *)insets {
    NSArray *unitTokens = [self consecutiveValuesOfTokenType:CASTokenTypeUnit];
    if (unitTokens.count == 1) {
        CGFloat value = [unitTokens[0] doubleValue];
        *insets = UIEdgeInsetsMake(value, value, value, value);
        return YES;
    }
    if (unitTokens.count == 2) {
        CGFloat value1 = [unitTokens[0] doubleValue];
        CGFloat value2 = [unitTokens[1] doubleValue];
        *insets = UIEdgeInsetsMake(value1, value2, value1, value2);
        return YES;
    }
    if (unitTokens.count == 4) {
        *insets = UIEdgeInsetsMake([unitTokens[0] doubleValue], [unitTokens[1] doubleValue], [unitTokens[2] doubleValue], [unitTokens[3] doubleValue]);
        return YES;
    }
    return NO;
}

- (BOOL)transformValuesToUIOffset:(UIOffset *)offset {
    NSArray *unitTokens = [self consecutiveValuesOfTokenType:CASTokenTypeUnit];
    if (unitTokens.count == 1) {
        CGFloat value = [unitTokens[0] doubleValue];
        *offset = UIOffsetMake(value, value);
        return YES;
    }
    if (unitTokens.count == 2) {
        CGFloat value1 = [unitTokens[0] doubleValue];
        CGFloat value2 = [unitTokens[1] doubleValue];
        *offset = UIOffsetMake(value1, value2);
        return YES;
    }
    return NO;
}

- (BOOL)transformValuesToUIColor:(UIColor **)color {
    UIColor *colorValue = [self valueOfTokenType:CASTokenTypeColor];
    if (colorValue) {
        *color = colorValue;
        return YES;
    }
    
    NSString *value = [self valueOfTokenType:CASTokenTypeRef]
    ?: [self valueOfTokenType:CASTokenTypeSelector]
    ?: [self valueOfTokenType:CASTokenTypeString];
    
    
    CASToken *alphaToken = [self.valueTokens lastObject];
    CGFloat alphaTokenValue = 1.0;
    
    BOOL hasAlphaToken = NO;
    
    if (alphaToken.type == CASTokenTypeUnit && alphaToken.value != nil) {
        float floatValue = [alphaToken.value floatValue];
        
        if (floatValue < 1 && floatValue >= 0) {
            hasAlphaToken = YES;
            alphaTokenValue = floatValue;
        }
    }
    
    if ([value isEqualToString:@"rgb"] || [value isEqualToString:@"rgba"] || [value isEqualToString:@"hsl"] || [value isEqualToString:@"hsla"]) {
        NSArray *unitTokens = [self consecutiveValuesOfTokenType:CASTokenTypeUnit];
        
        CGFloat alpha = 1.0;
        
        // invalid if you don't have 3 colors
        if(unitTokens.count < 3) {
            return NO;
        } else if(unitTokens.count == 4){
            alpha = [unitTokens[3] doubleValue];
        }
        
        if (hasAlphaToken) {
            alpha = alphaTokenValue;
        }
        
        if( [value isEqualToString:@"rgb"] || [value isEqualToString:@"rgba"] ) {
            if ([UIColor.class respondsToSelector:@selector(colorWithDisplayP3Red:green:blue:alpha:)]) {
                *color = [UIColor colorWithDisplayP3Red:[unitTokens[0] doubleValue]/255.0
                                                  green:[unitTokens[1] doubleValue]/255.0
                                                   blue:[unitTokens[2] doubleValue]/255.0
                                                  alpha:alpha];
            } else {
                *color = [UIColor colorWithRed:[unitTokens[0] doubleValue]/255.0
                                         green:[unitTokens[1] doubleValue]/255.0
                                          blue:[unitTokens[2] doubleValue]/255.0
                                         alpha:alpha];
            }
        } else if ( [value isEqualToString:@"hsl"] || [value isEqualToString:@"hsla"] ) {
            *color = [UIColor colorWithHue:[unitTokens[0] doubleValue]/360.0 saturation:[unitTokens[1] doubleValue]/100.0 brightness:[unitTokens[2] doubleValue]/100.0 alpha:alpha];
        }
        return YES;
    }
    
    value = [value cas_stringByCamelCasing];
    
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@Color", value]);
    if (selector && [UIColor.class respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        
        if (hasAlphaToken) {
            *color = [[UIColor.class performSelector:selector] colorWithAlphaComponent:alphaTokenValue];
        } else {
            *color = [UIColor.class performSelector:selector];
        }
        
#pragma clang diagnostic pop
        return YES;
    }
    
    return NO;}

- (BOOL)transformValuesToNSString:(NSString **)string {
    NSString *value = [self valueOfTokenType:CASTokenTypeString]
            ?: [self valueOfTokenType:CASTokenTypeRef]
                    ?: [self valueOfTokenType:CASTokenTypeSelector];
    if (value) {
        *string = value;
        return YES;
    }

    return NO;
}

- (BOOL)transformValuesToUIImage:(UIImage **)image {
    UIEdgeInsets insets;
    UIColor *tintColor = nil;
    
    NSString *imageName = [self valueOfTokenType:CASTokenTypeString] ?: [self valueOfTokenType:CASTokenTypeRef];
    
    BOOL hasInsets = [self transformValuesToUIEdgeInsets:&insets];
    
    BOOL hasTintColor = NO;
    
    if (self.valueTokens.count > 1) {
        // HACK to get the tintColor out.
        NSMutableArray *colorTokens = [NSMutableArray arrayWithArray:self.valueTokens];
        [colorTokens removeObjectAtIndex:0]; // Remove the image
        
        CASStyleProperty *styleProperty = [[CASStyleProperty alloc] initWithNameToken:self.nameToken valueTokens:colorTokens];
        
        [styleProperty transformValuesToUIColor:&tintColor];
        
        hasTintColor = tintColor != nil;
        // HACK
    }
    
    UIImage *imageValue = nil;
    NSRange schemeRange = [imageName rangeOfString:@"://"];
    if(schemeRange.location != NSNotFound) {

        // We are a file path instead
        NSString *scheme = [imageName substringToIndex:schemeRange.location];
        NSString *path = [imageName substringFromIndex:NSMaxRange(schemeRange)];

        // Checking if we're fetching from one of our built in
        // document uris
        NSSearchPathDirectory searchMask = 0;
        if([scheme isEqualToString:@"caches"]) {
            searchMask = NSCachesDirectory;
        } else if([scheme isEqualToString:@"documents"]) {
            searchMask = NSDocumentDirectory;
        } else if([scheme isEqualToString:@"appsupport"]) {
            searchMask = NSApplicationSupportDirectory;
        }

        if(searchMask != 0) {
            // If we found a search mask, then use that
            NSArray *paths = NSSearchPathForDirectoriesInDomains(searchMask, NSUserDomainMask, YES);
            NSString *imagePath = [paths firstObject];
            imageValue = [UIImage imageWithContentsOfFile:[imagePath stringByAppendingPathComponent:path]];
        } else {
            // Otherwise load from imageNamed as per norm
            imageValue = [UIImage imageNamed:path];
        }

    } else {
        // We're just an old boring image name
        imageValue = [UIImage imageNamed:imageName];
    }

    if (hasTintColor && tintColor) {
        imageValue = [imageValue tintedWithColor:tintColor];
    }
    
    if (hasInsets) {
        imageValue = [imageValue resizableImageWithCapInsets:insets];
    }
    if (imageValue) {
        *image = imageValue;
        return YES;
    }
    return NO;
}

- (BOOL)transformValuesToUIFont:(UIFont **)font
{
    NSNumber * fontSize = [self valueOfTokenType:CASTokenTypeUnit];
    NSString * fontName = [self valueOfTokenType:CASTokenTypeString]
            ?: [self valueOfTokenType:CASTokenTypeRef]
                    ?: [self valueOfTokenType:CASTokenTypeSelector];

    if (!fontSize && !fontName.length) {
        return NO;
    }

    static NSDictionary *textStyleLookupMap = nil;
    if (!textStyleLookupMap) {
        textStyleLookupMap = @{
               @"title1" : UIFontTextStyleTitle1,
               @"title2" : UIFontTextStyleTitle2,
               @"title3" : UIFontTextStyleTitle3,
               @"headline" : UIFontTextStyleHeadline,
               @"body" : UIFontTextStyleBody,
               @"callout" : UIFontTextStyleCallout,
               @"subhead" : UIFontTextStyleSubheadline,
               @"footnote" : UIFontTextStyleFootnote,
               @"caption1" : UIFontTextStyleCaption1,
               @"caption2" : UIFontTextStyleCaption2,
        };
    }

    static NSDictionary *textWeightLookupMap = nil;
    if (!textWeightLookupMap) {
        textWeightLookupMap = @{
                @"ultralight" : @(UIFontWeightUltraLight),
                @"thin" : @(UIFontWeightThin),
                @"light" : @(UIFontWeightLight),
                @"regular" : @(UIFontWeightRegular),
                @"semibold" : @(UIFontWeightSemibold),
                @"bold" : @(UIFontWeightBold),
                @"heavy" : @(UIFontWeightHeavy),
                @"black" : @(UIFontWeightBlack)
        };
    }

    NSString *textStyle = textStyleLookupMap[fontName];
    NSNumber *weightValue = textWeightLookupMap[fontName];

    if (textStyle && !fontSize) {
        *font = [UIFont preferredFontForTextStyle:textStyle];
    }
    if (weightValue && fontSize) {
        CGFloat fontSizeValue = [fontSize floatValue] ?: [UIFont systemFontSize];
        CGFloat weight = [weightValue floatValue];
        *font =  [UIFont systemFontOfSize:fontSizeValue weight:weight];
    } else {
        CGFloat fontSizeValue = [fontSize floatValue] ?: [UIFont systemFontSize];
        if (fontName) {
            *font = [UIFont fontWithName:fontName size:fontSizeValue];
        } else {
            *font = [UIFont systemFontOfSize:fontSizeValue];
        }
    }
    return YES;
}

- (void)resolveExpressions {
    BOOL hasOperator = NO;
    for (CASToken *token in self.valueTokens) {
        if (token.type == CASTokenTypeOperator && ![token valueIsEqualTo:@","]) {
            hasOperator = YES;
            break;
        }
    }

    if (!hasOperator) return;

    CASExpressionSolver *solver = CASExpressionSolver.new;
    self.valueTokens = [solver tokensByReducingTokens:self.valueTokens];
    self.values = nil;
}

- (void)addChildStyleProperty:(CASStyleProperty *)styleProperty {
    if (!_childStyleProperties) {
        _childStyleProperties = NSMutableArray.new;
    }
    [_childStyleProperties addObject:styleProperty];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (nil != self) {
        self.name = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(name))];
        self.values = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(values))];
        self.nameToken = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(nameToken))];
        self.valueTokens = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(valueTokens))];
        _childStyleProperties = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(childStyleProperties))];
        self.arguments = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(arguments))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:NSStringFromSelector(@selector(name))];
    [aCoder encodeObject:self.values forKey:NSStringFromSelector(@selector(values))];
    [aCoder encodeObject:self.nameToken forKey:NSStringFromSelector(@selector(nameToken))];
    [aCoder encodeObject:self.valueTokens forKey:NSStringFromSelector(@selector(valueTokens))];
    [aCoder encodeObject:_childStyleProperties forKey:NSStringFromSelector(@selector(childStyleProperties))];
    [aCoder encodeObject:self.arguments forKey:NSStringFromSelector(@selector(arguments))];
}

@end
