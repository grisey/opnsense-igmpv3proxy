<script>
$(document).ready(function() {
    function field(id) {
        return $('[id="' + id + '"]');
    }

    function rowOf(element) {
        return element.closest('tr');
    }

    function replaceAliasField(modelFieldId, selectId, endpoint) {
        const modelField = field(modelFieldId);
        const currentValue = modelField.val() || "";
        const select = $('<select id="' + selectId + '" class="selectpicker" data-live-search="true" data-width="320px"></select>');

        ajaxCall(endpoint, {}, function(data, status) {
            select.empty();

            if (status === "success" && data.status === "ok") {
                $.each(data.aliases, function(key, label) {
                    select.append($("<option></option>").attr("value", key).text(label));
                });
            }

            modelField.hide();
            modelField.after(select);

            if (currentValue) {
                select.val(currentValue);
            }

            select.selectpicker();
            select.selectpicker('refresh');

            modelField.val(select.val() || "");

            select.change(function() {
                modelField.val($(this).val() || "");
            });
        });
    }

    function syncAliasSelect(selectId, modelFieldId) {
        const select = $("#" + selectId);
        if (select.length) {
            field(modelFieldId).val(select.val() || field(modelFieldId).val() || "");
        }
    }

    function syncGlobalAliasMode() {
        const useAliases = field("igmpv3proxy.use_aliases").is(":checked");

        field("igmpv3proxy.upstream_whitelist_alias_enabled").prop("checked", useAliases);
        field("igmpv3proxy.downstream_whitelist_alias_enabled").prop("checked", useAliases);
        field("igmpv3proxy.source_filter_alias_enabled").prop("checked", useAliases);
    }

    function toggleRows() {
        syncGlobalAliasMode();

        const useAliases = field("igmpv3proxy.use_aliases").is(":checked");
        const sourceFilterEnabled = field("igmpv3proxy.source_filter_enabled").is(":checked");

        // versteckte interne Einzel-Haken
        rowOf(field("igmpv3proxy.upstream_whitelist_alias_enabled")).hide();
        rowOf(field("igmpv3proxy.downstream_whitelist_alias_enabled")).hide();
        rowOf(field("igmpv3proxy.source_filter_alias_enabled")).hide();

        // upstream whitelist
        rowOf(field("igmpv3proxy.upstream_whitelist_alias")).toggle(useAliases);
        rowOf(field("igmpv3proxy.upstream_whitelist")).toggle(!useAliases);

        // downstream whitelist
        rowOf(field("igmpv3proxy.downstream_whitelist_alias")).toggle(useAliases);
        rowOf(field("igmpv3proxy.downstream_whitelist")).toggle(!useAliases);

        // source filter
        rowOf(field("igmpv3proxy.source_filter_source_alias")).toggle(sourceFilterEnabled && useAliases);
        rowOf(field("igmpv3proxy.source_filter_sources")).toggle(sourceFilterEnabled && !useAliases);
    }

    mapDataToFormUI({'frm_GeneralSettings': "/api/igmpv3proxy/settings/get"}).done(function() {
        formatTokenizersUI();
        $('.selectpicker').selectpicker('refresh');

        replaceAliasField("igmpv3proxy.source_filter_source_alias", "source_filter_source_alias_select", "/api/igmpv3proxy/aliases/source");
        replaceAliasField("igmpv3proxy.upstream_whitelist_alias", "upstream_whitelist_alias_select", "/api/igmpv3proxy/aliases/multicast");
        replaceAliasField("igmpv3proxy.downstream_whitelist_alias", "downstream_whitelist_alias_select", "/api/igmpv3proxy/aliases/multicast");

        toggleRows();

        field("igmpv3proxy.use_aliases").change(toggleRows);
        field("igmpv3proxy.source_filter_enabled").change(toggleRows);

        updateServiceControlUI('igmpv3proxy');
    });

    $("#reconfigureAct").SimpleActionButton({
        onPreAction: function() {
            const dfObj = $.Deferred();

            syncGlobalAliasMode();

            syncAliasSelect("source_filter_source_alias_select", "igmpv3proxy.source_filter_source_alias");
            syncAliasSelect("upstream_whitelist_alias_select", "igmpv3proxy.upstream_whitelist_alias");
            syncAliasSelect("downstream_whitelist_alias_select", "igmpv3proxy.downstream_whitelist_alias");

            saveFormToEndpoint(
                "/api/igmpv3proxy/settings/set",
                'frm_GeneralSettings',
                dfObj.resolve,
                true,
                dfObj.reject
            );
            return dfObj;
        },
        onAction: function(data, status) {
            updateServiceControlUI('igmpv3proxy');
        }
    });

    updateServiceControlUI('igmpv3proxy');
});
</script>

<section class="page-content-main">
    <div class="content-box">
        {{ partial("layout_partials/base_form", ['fields': general, 'id': 'frm_GeneralSettings']) }}
    </div>

    <br/>

    <div class="content-box">
        <div class="col-md-12">
            <br/>
            <button class="btn btn-primary" id="reconfigureAct"
                    data-endpoint="/api/igmpv3proxy/service/reconfigure"
                    data-label="{{ lang._('Apply') }}"
                    type="button">
                {{ lang._('Apply') }}
            </button>
            <br/><br/>
        </div>
    </div>
</section>
