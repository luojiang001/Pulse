package com.tjetc.repository;

import com.tjetc.document.MedicineDoc;
import com.tjetc.domain.Medicine;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.annotations.Highlight;
import org.springframework.data.elasticsearch.annotations.HighlightField;
import org.springframework.data.elasticsearch.annotations.HighlightParameters;
import org.springframework.data.elasticsearch.core.SearchPage;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MedicineEsRepository extends ElasticsearchRepository<MedicineDoc, Integer> {
    @Highlight(fields = {
            @HighlightField(name = "name")},
            parameters =
            @HighlightParameters(preTags = "<strong><font style='color:red'>", postTags = "</font></strong>", fragmentSize = 500, numberOfFragments = 3))
    SearchPage<Medicine> findByName(String name, Pageable pageable);
}
