module encoderherocomplex

import time

struct FullPerson {
    id       int
    name     string
    age      int
    birthday time.Time
    car      FullCar
    profiles []FullProfile
}

struct FullCar {
    name      string
    year      int
    insurance FullInsurance
}

struct FullInsurance {
    provider   string
    expiration time.Time
}

struct FullProfile {
    platform string
    url      string
}

fn test_roundtrip_nested_struct() ! {
    original := FullPerson{
        id:   1
        name: 'Alice'
        age:  30
        birthday: time.new(year: 1993, month: 6, day: 15)
        car: FullCar{
            name: 'Tesla'
            year: 2024
            insurance: FullInsurance{
                provider: 'StateFarm'
                expiration: time.new(year: 2025, month: 12, day: 31)
            }
        }
        profiles: [
            FullProfile{platform: 'GitHub', url: 'github.com/alice'},
            FullProfile{platform: 'LinkedIn', url: 'linkedin.com/alice'},
        ]
    }
    
    // Encode
    encoded := encode[FullPerson](original)!
    println('Encoded:\n${encoded}\n')
    
    // Decode
    decoded := decode[FullPerson](encoded)!
    
    // Verify
    assert decoded.id == original.id
    assert decoded.name == original.name
    assert decoded.age == original.age
    assert decoded.car.name == original.car.name
    assert decoded.car.year == original.car.year
    assert decoded.car.insurance.provider == original.car.insurance.provider
    assert decoded.profiles.len == original.profiles.len
    assert decoded.profiles[0].platform == original.profiles[0].platform
    assert decoded.profiles[1].url == original.profiles[1].url
}

fn test_roundtrip_flat_struct() ! {
    struct Simple {
        id   int
        name string
        age  int
    }
    
    original := Simple{id: 123, name: 'Bob', age: 25}
    encoded := encode[Simple](original)!
    decoded := decode[Simple](encoded)!
    
    assert decoded.id == original.id
    assert decoded.name == original.name
    assert decoded.age == original.age
}