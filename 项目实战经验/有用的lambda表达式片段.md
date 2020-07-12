# 取出map中所有的value并排序合并成list
```java
        // 因为合并了数据，所以需要重新排序
        List<TranAnalysticPageCustomDto> sortedTranAnalysticPageCustomDtoList = resultMap.entrySet()
                .stream()
                .map(Map.Entry::getValue)
                .sorted(Comparator.comparing(TranAnalysticPageCustomDto::getPv).reversed())
                .collect(Collectors.toList());
```

# 按 实体中的某个字段的值来分组
```java
Map<String, List<String>> filedMaps =
                    fieldErrorList.stream().
                            collect(groupingBy(FieldError :: getField,
                                    Collectors.mapping(FieldError :: getDefaultMessage, Collectors.toList())));
```

# Map 的merge

- 如果值不存在，就等同于 put(key, value), 假如存在，就以某种方式 merge old value 和 new value

- reMapping 的 参数是 (V oldValue, V newValue) -> V



