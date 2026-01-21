#include <algorithm>
#include <cctype>
#include <cmath>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <variant>
#include <vector>

#include <emscripten/bind.h>
#include <emscripten/val.h>
#include <emscripten.h>

#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include <GLFW/glfw3.h>

using emscripten::val;

struct Color {
    int r = 255;
    int g = 255;
    int b = 255;
};

using Value = std::variant<std::monostate, bool, double, std::string, Color>;

struct AppState {
    bool visible = false;
    bool pinned = false;
    bool free_control = false;
    bool just_opened = false;
    std::string title = "Menu";
    std::string search;
    std::string hint = "Esc to close";
    std::string selected_effect_id;
    std::unordered_set<std::string> collapsed;
    std::unordered_map<std::string, Value> values;
    std::unordered_map<std::string, std::string> text_inputs;
    std::unordered_map<std::string, std::string> text_areas;
    val data = val::undefined();
    bool dragging_window = false;
    std::unordered_map<std::string, double> color_last_sent;
};

static AppState g_state;
static GLFWwindow* g_window = nullptr;

static std::string to_lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return s;
}

static bool is_defined(const val& v) {
    return !v.isUndefined() && !v.isNull();
}

static bool is_array(const val& v) {
    return is_defined(v) && v.instanceof(val::global("Array"));
}

static bool is_object(const val& v) {
    if (!is_defined(v)) return false;
    if (is_array(v)) return false;
    return v.typeOf().as<std::string>() == "object";
}

static std::string get_string(const val& obj, const char* key, const std::string& fallback = "") {
    if (!is_defined(obj)) return fallback;
    val v = obj[key];
    if (!is_defined(v)) return fallback;
    if (v.typeOf().as<std::string>() == "string") return v.as<std::string>();
    return fallback;
}

static double get_number(const val& obj, const char* key, double fallback = 0.0) {
    if (!is_defined(obj)) return fallback;
    val v = obj[key];
    if (!is_defined(v)) return fallback;
    if (v.typeOf().as<std::string>() == "number") return v.as<double>();
    return fallback;
}

static bool get_bool(const val& obj, const char* key, bool fallback = false) {
    if (!is_defined(obj)) return fallback;
    val v = obj[key];
    if (!is_defined(v)) return fallback;
    if (v.typeOf().as<std::string>() == "boolean") return v.as<bool>();
    return fallback;
}

static Color val_to_color(const val& obj, const Color& fallback) {
    if (!is_object(obj)) return fallback;
    Color c = fallback;
    if (is_defined(obj["r"])) c.r = static_cast<int>(obj["r"].as<double>());
    if (is_defined(obj["g"])) c.g = static_cast<int>(obj["g"].as<double>());
    if (is_defined(obj["b"])) c.b = static_cast<int>(obj["b"].as<double>());
    return c;
}

static Value val_to_value(const val& v) {
    if (!is_defined(v)) return std::monostate{};
    const std::string type = v.typeOf().as<std::string>();
    if (type == "boolean") return v.as<bool>();
    if (type == "number") return v.as<double>();
    if (type == "string") return v.as<std::string>();
    if (type == "object") {
        if (is_defined(v["r"]) || is_defined(v["g"]) || is_defined(v["b"])) {
            return val_to_color(v, Color{255, 255, 255});
        }
    }
    return std::monostate{};
}

static bool value_to_bool(const Value& value, bool fallback = false) {
    if (auto v = std::get_if<bool>(&value)) return *v;
    return fallback;
}

static double value_to_number(const Value& value, double fallback = 0.0) {
    if (auto v = std::get_if<double>(&value)) return *v;
    return fallback;
}

static std::string value_to_string(const Value& value, const std::string& fallback = "") {
    if (auto v = std::get_if<std::string>(&value)) return *v;
    return fallback;
}

static Color value_to_color(const Value& value, const Color& fallback) {
    if (auto v = std::get_if<Color>(&value)) return *v;
    return fallback;
}

static void merge_payload(val& target, const val& source) {
    if (!is_object(source)) return;
    val keys = val::global("Object").call<val>("keys", source);
    const int len = keys["length"].as<int>();
    for (int i = 0; i < len; ++i) {
        const std::string key = keys[i].as<std::string>();
        target.set(key, source[key]);
    }
}

static void post_nui(const std::string& callback, const val& payload) {
    if (callback.empty()) return;
    val fn = val::global("postNui");
    if (!is_defined(fn)) return;
    fn(callback, payload);
}

static void update_hint_default() {
    if (g_state.free_control) {
        g_state.hint = "Free control enabled - press F10 to refocus";
    } else if (g_state.pinned) {
        g_state.hint = "Pinned (Esc disabled)";
    } else {
        g_state.hint = "Esc to close";
    }
}

static void init_defaults_from_node(const val& node) {
    if (!is_object(node)) return;
    const std::string type = get_string(node, "type", "");
    if (type == "group") {
        val children = node["children"];
        if (is_array(children)) {
            const int len = children["length"].as<int>();
            for (int i = 0; i < len; ++i) {
                init_defaults_from_node(children[i]);
            }
        }
        return;
    }

    const std::string key = get_string(node, "key", "");
    if (!key.empty() && g_state.values.find(key) == g_state.values.end()) {
        if (is_defined(node["default"])) {
            g_state.values[key] = val_to_value(node["default"]);
        } else {
            g_state.values[key] = std::monostate{};
        }
    }

    val inline_toggle = node["inlineToggle"];
    if (is_object(inline_toggle)) {
        const std::string ikey = get_string(inline_toggle, "key", "");
        if (!ikey.empty() && g_state.values.find(ikey) == g_state.values.end()) {
            if (is_defined(inline_toggle["default"])) {
                g_state.values[ikey] = val_to_value(inline_toggle["default"]);
            } else {
                g_state.values[ikey] = false;
            }
        }
    }
}

static void init_defaults_from_data() {
    if (!is_object(g_state.data)) return;
    val globals = g_state.data["globalGroups"];
    if (is_array(globals)) {
        const int len = globals["length"].as<int>();
        for (int i = 0; i < len; ++i) {
            init_defaults_from_node(globals[i]);
        }
    }
    val effects = g_state.data["effects"];
    if (is_array(effects)) {
        const int len = effects["length"].as<int>();
        for (int i = 0; i < len; ++i) {
            val fx = effects[i];
            val groups = fx["groups"];
            if (is_array(groups)) {
                const int glen = groups["length"].as<int>();
                for (int g = 0; g < glen; ++g) {
                    init_defaults_from_node(groups[g]);
                }
            }
        }
    }
}

static void collect_group_ids(const val& node, std::vector<std::string>& ids) {
    if (!is_object(node)) return;
    const std::string type = get_string(node, "type", "");
    if (type != "group") return;
    const std::string id = get_string(node, "id", "");
    if (!id.empty()) ids.push_back(id);
    val children = node["children"];
    if (is_array(children)) {
        const int len = children["length"].as<int>();
        for (int i = 0; i < len; ++i) {
            collect_group_ids(children[i], ids);
        }
    }
}

static void maybe_select_default_effect() {
    if (!g_state.selected_effect_id.empty()) return;
    val effects = g_state.data["effects"];
    if (!is_array(effects)) return;
    if (effects["length"].as<int>() <= 0) return;
    val first = effects[0];
    g_state.selected_effect_id = get_string(first, "id", "");
}

static int InputTextCallback(ImGuiInputTextCallbackData* data) {
    if (data->EventFlag == ImGuiInputTextFlags_CallbackResize) {
        auto* str = static_cast<std::string*>(data->UserData);
        str->resize(static_cast<size_t>(data->BufTextLen));
        data->Buf = str->data();
    }
    return 0;
}

static bool InputTextString(const char* label, std::string* str, ImGuiInputTextFlags flags = 0) {
    if (str->capacity() < 64) str->reserve(64);
    flags |= ImGuiInputTextFlags_CallbackResize;
    return ImGui::InputText(label, str->data(), str->capacity() + 1, flags, InputTextCallback, str);
}

static bool InputTextWithHintString(const char* label, const char* hint, std::string* str, ImGuiInputTextFlags flags = 0) {
    if (str->capacity() < 64) str->reserve(64);
    flags |= ImGuiInputTextFlags_CallbackResize;
    return ImGui::InputTextWithHint(label, hint, str->data(), str->capacity() + 1, flags, InputTextCallback, str);
}

static bool InputTextMultilineString(const char* label, std::string* str, const ImVec2& size, ImGuiInputTextFlags flags = 0) {
    if (str->capacity() < 256) str->reserve(256);
    flags |= ImGuiInputTextFlags_CallbackResize;
    return ImGui::InputTextMultiline(label, str->data(), str->capacity() + 1, size, flags, InputTextCallback, str);
}

static std::string control_uid(const std::string& scope, const val& control, int index) {
    std::string label = get_string(control, "label", "");
    std::string key = get_string(control, "key", "");
    std::string id = get_string(control, "id", "");
    std::string uid = scope + "::" + std::to_string(index);
    if (!id.empty()) uid += "::" + id;
    if (!key.empty()) uid += "::" + key;
    if (!label.empty()) uid += "::" + label;
    return uid;
}

static void render_control(const val& control, const std::string& scope, int index, bool disabled) {
    const std::string type = get_string(control, "type", "");
    const std::string label = get_string(control, "label", "");
    const std::string key = get_string(control, "key", "");
    const std::string callback = get_string(control, "callback", "");
    const std::string uid = control_uid(scope, control, index);

    ImGui::TableNextRow();
    ImGui::TableSetColumnIndex(0);
    ImGui::TextWrapped("%s", label.c_str());
    ImGui::TableSetColumnIndex(1);
    ImGui::PushID(uid.c_str());
    if (disabled) ImGui::BeginDisabled();

    if (type == "button") {
        const std::string button_label = get_string(control, "buttonLabel", "Run");
        if (ImGui::Button(button_label.c_str())) {
            val payload = val::object();
            merge_payload(payload, control["meta"]);
            merge_payload(payload, control["payload"]);
            val state_keys = control["stateKeys"];
            if (is_array(state_keys)) {
                const int len = state_keys["length"].as<int>();
                for (int i = 0; i < len; ++i) {
                    const std::string skey = state_keys[i].as<std::string>();
                    auto it = g_state.values.find(skey);
                    if (it != g_state.values.end()) {
                        const Value& v = it->second;
                        if (auto b = std::get_if<bool>(&v)) payload.set(skey, *b);
                        else if (auto n = std::get_if<double>(&v)) payload.set(skey, *n);
                        else if (auto s = std::get_if<std::string>(&v)) payload.set(skey, *s);
                        else if (auto c = std::get_if<Color>(&v)) {
                            val color = val::object();
                            color.set("r", c->r);
                            color.set("g", c->g);
                            color.set("b", c->b);
                            payload.set(skey, color);
                        }
                    }
                }
            }
            post_nui(callback, payload);
        }
    } else if (type == "toggle") {
        bool current = value_to_bool(g_state.values[key], get_bool(control, "default", false));
        if (ImGui::Checkbox("##toggle", &current)) {
            g_state.values[key] = current;
            val payload = val::object();
            payload.set("key", key);
            payload.set("value", current);
            merge_payload(payload, control["meta"]);
            post_nui(callback, payload);
        }
    } else if (type == "slider") {
        double min = get_number(control, "min", 0.0);
        double max = get_number(control, "max", 1.0);
        double step = get_number(control, "step", 0.01);
        double current = value_to_number(g_state.values[key], get_number(control, "default", min));
        float slider_val = static_cast<float>(current);
        const float slider_min = static_cast<float>(min);
        const float slider_max = static_cast<float>(max);
        bool changed = ImGui::SliderFloat("##slider", &slider_val, slider_min, slider_max);
        ImGui::SameLine();
        ImGui::SetNextItemWidth(80.0f);
        float input_val = slider_val;
        if (ImGui::InputFloat("##slider_input", &input_val, static_cast<float>(step), static_cast<float>(step * 10.0), "%.3f")) {
            slider_val = input_val;
            changed = true;
        }
        if (changed) {
            double clamped = std::min(max, std::max(min, static_cast<double>(slider_val)));
            g_state.values[key] = clamped;
            val payload = val::object();
            payload.set("key", key);
            payload.set("value", clamped);
            merge_payload(payload, control["meta"]);
            post_nui(callback, payload);
        }
    } else if (type == "select" || type == "dropdown") {
        val options = control["options"];
        std::vector<std::string> opts;
        if (is_array(options)) {
            const int len = options["length"].as<int>();
            opts.reserve(len);
            for (int i = 0; i < len; ++i) {
                opts.push_back(options[i].as<std::string>());
            }
        }
        std::string current = value_to_string(g_state.values[key], get_string(control, "default", ""));
        int current_idx = 0;
        for (size_t i = 0; i < opts.size(); ++i) {
            if (opts[i] == current) {
                current_idx = static_cast<int>(i);
                break;
            }
        }
        if (ImGui::BeginCombo("##select", opts.empty() ? "" : opts[current_idx].c_str())) {
            for (size_t i = 0; i < opts.size(); ++i) {
                bool selected = (static_cast<int>(i) == current_idx);
                if (ImGui::Selectable(opts[i].c_str(), selected)) {
                    current_idx = static_cast<int>(i);
                    const std::string next = opts[i];
                    g_state.values[key] = next;
                    val payload = val::object();
                    payload.set("key", key);
                    payload.set("value", next);
                    merge_payload(payload, control["meta"]);
                    post_nui(callback, payload);
                }
                if (selected) ImGui::SetItemDefaultFocus();
            }
            ImGui::EndCombo();
        }
    } else if (type == "inputButton") {
        std::string& input = g_state.text_inputs[uid];
        if (input.empty()) input = "";

        val inline_toggle = control["inlineToggle"];
        if (is_object(inline_toggle)) {
            const std::string it_label = get_string(inline_toggle, "label", "");
            const std::string it_key = get_string(inline_toggle, "key", "");
            const std::string it_callback = get_string(inline_toggle, "callback", "");
            bool enabled = value_to_bool(g_state.values[it_key], get_bool(inline_toggle, "default", false));
            if (ImGui::Checkbox(it_label.c_str(), &enabled)) {
                g_state.values[it_key] = enabled;
                val payload = val::object();
                payload.set("key", it_key);
                payload.set("enabled", enabled);
                payload.set("value", enabled);
                merge_payload(payload, inline_toggle["meta"]);
                post_nui(it_callback, payload);
            }
            ImGui::SameLine();
        }

        const std::string placeholder = get_string(control, "placeholder", "");
        ImGui::SetNextItemWidth(220.0f);
        InputTextWithHintString("##input", placeholder.c_str(), &input);
        ImGui::SameLine();
        const std::string button_label = get_string(control, "buttonLabel", "Go");
        if (ImGui::Button(button_label.c_str())) {
            const std::string payload_key = get_string(control, "payloadKey", "value");
            val payload = val::object();
            payload.set(payload_key, input);
            merge_payload(payload, control["meta"]);
            post_nui(callback, payload);
        }
    } else if (type == "textarea") {
        std::string& text = g_state.text_areas[uid];
        if (text.empty()) {
            text = value_to_string(g_state.values[key], get_string(control, "default", ""));
        }
        const int rows = static_cast<int>(get_number(control, "rows", 4.0));
        ImGui::SetNextItemWidth(-1.0f);
        if (InputTextMultilineString("##textarea", &text, ImVec2(0, ImGui::GetTextLineHeight() * rows))) {
            g_state.values[key] = text;
        }
        if (ImGui::IsItemDeactivatedAfterEdit()) {
            val payload = val::object();
            payload.set("key", key);
            payload.set("value", text);
            merge_payload(payload, control["meta"]);
            post_nui(callback, payload);
        }
    } else if (type == "number") {
        double min = get_number(control, "min", 0.0);
        double max = get_number(control, "max", 999999.0);
        double step = get_number(control, "step", 1.0);
        double current = value_to_number(g_state.values[key], get_number(control, "default", 0.0));
        float input_val = static_cast<float>(current);
        if (ImGui::InputFloat("##number", &input_val, static_cast<float>(step), static_cast<float>(step * 10.0), "%.3f")) {
            double clamped = std::min(max, std::max(min, static_cast<double>(input_val)));
            g_state.values[key] = clamped;
            val payload = val::object();
            payload.set("key", key);
            payload.set("value", clamped);
            merge_payload(payload, control["meta"]);
            post_nui(callback, payload);
        }
    } else if (type == "colorPicker") {
        Color def_color = val_to_color(control["default"], Color{255, 255, 255});
        Color current = value_to_color(g_state.values[key], def_color);
        float col[3] = {
            current.r / 255.0f,
            current.g / 255.0f,
            current.b / 255.0f
        };
        const bool changed = ImGui::ColorEdit3("##color", col, ImGuiColorEditFlags_NoAlpha);
        if (changed) {
            Color next{
                static_cast<int>(std::round(col[0] * 255.0f)),
                static_cast<int>(std::round(col[1] * 255.0f)),
                static_cast<int>(std::round(col[2] * 255.0f))
            };
            g_state.values[key] = next;
            const double now = ImGui::GetTime();
            const double last = g_state.color_last_sent[uid];
            if ((now - last) >= 0.12) {
                g_state.color_last_sent[uid] = now;
                val payload = val::object();
                payload.set("key", key);
                val color = val::object();
                color.set("r", next.r);
                color.set("g", next.g);
                color.set("b", next.b);
                payload.set("value", color);
                merge_payload(payload, control["meta"]);
                post_nui(callback, payload);
            }
        }
        if (ImGui::IsItemDeactivatedAfterEdit()) {
            Color final_color = value_to_color(g_state.values[key], def_color);
            val payload = val::object();
            payload.set("key", key);
            val color = val::object();
            color.set("r", final_color.r);
            color.set("g", final_color.g);
            color.set("b", final_color.b);
            payload.set("value", color);
            merge_payload(payload, control["meta"]);
            post_nui(callback, payload);
        }
    } else {
        ImGui::TextDisabled("(unsupported control: %s)", type.c_str());
    }

    if (disabled) ImGui::EndDisabled();
    ImGui::PopID();
}

static void render_group(const val& group, const std::string& scope, bool parent_disabled) {
    const std::string id = get_string(group, "id", "");
    const std::string label = get_string(group, "label", "");
    bool open = g_state.collapsed.find(id) == g_state.collapsed.end();
    const bool disabled = parent_disabled || get_bool(group, "disabled", false);
    const std::string disabled_reason = get_string(group, "disabledReason", "");
    ImGui::SetNextItemOpen(open, ImGuiCond_Always);
    if (ImGui::CollapsingHeader(label.c_str())) {
        if (!open) g_state.collapsed.erase(id);
        if (disabled && !disabled_reason.empty()) {
            ImGui::TextDisabled("%s", disabled_reason.c_str());
        }
        val children = group["children"];
        if (is_array(children)) {
            const std::string child_scope = scope + "/" + id;
            if (ImGui::BeginTable((child_scope + "_table").c_str(), 2, ImGuiTableFlags_SizingStretchProp)) {
                ImGui::TableSetupColumn("Label", ImGuiTableColumnFlags_WidthFixed, 200.0f);
                ImGui::TableSetupColumn("Control", ImGuiTableColumnFlags_WidthStretch);
                const int len = children["length"].as<int>();
                int control_index = 0;
                if (disabled) ImGui::BeginDisabled();
                for (int i = 0; i < len; ++i) {
                    val child = children[i];
                    if (!is_object(child)) continue;
                    const std::string type = get_string(child, "type", "");
                    if (type == "group") {
                        if (disabled) ImGui::EndDisabled();
                        ImGui::EndTable();
                        render_group(child, child_scope, disabled);
                        if (ImGui::BeginTable((child_scope + "_table").c_str(), 2, ImGuiTableFlags_SizingStretchProp)) {
                            ImGui::TableSetupColumn("Label", ImGuiTableColumnFlags_WidthFixed, 200.0f);
                            ImGui::TableSetupColumn("Control", ImGuiTableColumnFlags_WidthStretch);
                        }
                        if (disabled) ImGui::BeginDisabled();
                        continue;
                    }
                    const bool control_disabled = disabled || get_bool(child, "disabled", false);
                    render_control(child, child_scope, control_index++, control_disabled);
                }
                if (disabled) ImGui::EndDisabled();
                ImGui::EndTable();
            }
        }
    } else {
        if (open) g_state.collapsed.insert(id);
    }
}

static void render_effect_list() {
    val effects = g_state.data["effects"];
    if (!is_array(effects)) return;
    const std::string q = to_lower(g_state.search);
    const int len = effects["length"].as<int>();
    const ImVec4 desc_color(0.75f, 0.78f, 0.82f, 0.65f);
    for (int i = 0; i < len; ++i) {
        val fx = effects[i];
        const std::string id = get_string(fx, "id", "");
        const std::string label = get_string(fx, "label", "(unnamed)");
        const std::string sub = get_string(fx, "sub", "");
        if (!q.empty()) {
            std::string combined = to_lower(label + " " + sub);
            if (combined.find(q) == std::string::npos) continue;
        }
        bool selected = (id == g_state.selected_effect_id);
        ImGui::PushID(id.c_str());
        if (ImGui::Selectable(label.c_str(), selected)) {
            g_state.selected_effect_id = id;
            val callbacks = g_state.data["callbacks"];
            const std::string select_cb = get_string(callbacks, "selectEffect", "selectEffect");
            val payload = val::object();
            payload.set("id", id);
            post_nui(select_cb, payload);
        }
        if (!sub.empty()) {
            ImGui::Indent();
            ImGui::PushStyleColor(ImGuiCol_Text, desc_color);
            ImGui::TextWrapped("%s", sub.c_str());
            ImGui::PopStyleColor();
            ImGui::Unindent();
        }
        ImGui::PopID();
    }
}

static void render_detail_panel() {
    bool has_any = false;
    val globals = g_state.data["globalGroups"];
    if (is_array(globals)) {
        const int len = globals["length"].as<int>();
        has_any = has_any || (len > 0);
        for (int i = 0; i < len; ++i) {
            render_group(globals[i], "global", false);
        }
    }

    val effects = g_state.data["effects"];
    if (!is_array(effects)) {
        if (!has_any) ImGui::TextDisabled("No data is passed.");
        return;
    }
    const int len = effects["length"].as<int>();
    has_any = has_any || (len > 0);
    for (int i = 0; i < len; ++i) {
        val fx = effects[i];
        if (get_string(fx, "id", "") != g_state.selected_effect_id) continue;
        val groups = fx["groups"];
        if (is_array(groups)) {
            const int glen = groups["length"].as<int>();
            for (int g = 0; g < glen; ++g) {
                val group = groups[g];
                if (get_string(group, "type", "") == "group") {
                    render_group(group, "effect", false);
                }
            }
        } else {
            ImGui::TextDisabled("No details available.");
        }
        return;
    }

    if (!has_any) ImGui::TextDisabled("No data is passed.");
}

static void render_ui() {
    if (!g_state.visible) return;
    const bool alpha_pushed = g_state.free_control;
    if (alpha_pushed) {
        ImGui::PushStyleVar(ImGuiStyleVar_Alpha, 0.5f);
    }

    ImGuiIO& io = ImGui::GetIO();
    const ImVec2 init_win_size(io.DisplaySize.x * 0.8f, io.DisplaySize.y * 0.8f);
    const ImVec2 init_win_pos((io.DisplaySize.x - init_win_size.x) * 0.5f, (io.DisplaySize.y - init_win_size.y) * 0.5f);
    ImGui::SetNextWindowSize(init_win_size, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowPos(init_win_pos, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSizeConstraints(
        ImVec2(io.DisplaySize.x * 0.4f, io.DisplaySize.y * 0.4f),
        ImVec2(io.DisplaySize.x * 0.98f, io.DisplaySize.y * 0.98f)
    );
    ImGuiWindowFlags flags = ImGuiWindowFlags_NoCollapse;
    ImGui::Begin("cq-admin", nullptr, flags);

    ImGuiViewport* vp = ImGui::GetMainViewport();
    const ImVec2 vp_pos = vp->Pos;
    const ImVec2 vp_size = vp->Size;
    const ImVec2 win_pos = ImGui::GetWindowPos();
    const ImVec2 win_size = ImGui::GetWindowSize();
    const float threshold = 16.0f;

    const float dist_left = win_pos.x - vp_pos.x;
    const float dist_top = win_pos.y - vp_pos.y;
    const float dist_right = (vp_pos.x + vp_size.x) - (win_pos.x + win_size.x);
    const float dist_bottom = (vp_pos.y + vp_size.y) - (win_pos.y + win_size.y);

    const bool near_left = dist_left <= threshold;
    const bool near_right = dist_right <= threshold;
    const bool near_top = dist_top <= threshold;
    const bool near_bottom = dist_bottom <= threshold;

    ImVec2 clamped_pos = win_pos;
    clamped_pos.x = std::min(std::max(clamped_pos.x, vp_pos.x), std::max(vp_pos.x, vp_pos.x + vp_size.x - win_size.x));
    clamped_pos.y = std::min(std::max(clamped_pos.y, vp_pos.y), std::max(vp_pos.y, vp_pos.y + vp_size.y - win_size.y));

    const bool dragging = ImGui::IsMouseDragging(0) &&
        (ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows) ||
         ImGui::IsWindowHovered(ImGuiHoveredFlags_RootAndChildWindows));
    if (dragging) {
        ImGui::SetWindowPos(clamped_pos, ImGuiCond_Always);
        g_state.dragging_window = true;
    }

    if (g_state.dragging_window && ImGui::IsMouseReleased(0)) {
        ImVec2 snap_pos = clamped_pos;
        if (near_left) snap_pos.x = vp_pos.x;
        if (near_right) snap_pos.x = std::max(vp_pos.x, vp_pos.x + vp_size.x - win_size.x);
        if (near_top) snap_pos.y = vp_pos.y;
        if (near_bottom) snap_pos.y = std::max(vp_pos.y, vp_pos.y + vp_size.y - win_size.y);
        ImGui::SetWindowPos(snap_pos, ImGuiCond_Always);
        g_state.dragging_window = false;
    }

    const ImU32 edge_color = ImGui::GetColorU32(ImVec4(0.20f, 0.45f, 0.78f, 0.55f));
    ImDrawList* fg = ImGui::GetForegroundDrawList();
    if (near_left) {
        fg->AddRectFilled(ImVec2(vp_pos.x, vp_pos.y), ImVec2(vp_pos.x + 6.0f, vp_pos.y + vp_size.y), edge_color);
        fg->AddRectFilled(ImVec2(win_pos.x, win_pos.y), ImVec2(win_pos.x + 2.0f, win_pos.y + win_size.y), edge_color);
    }
    if (near_right) {
        fg->AddRectFilled(ImVec2(vp_pos.x + vp_size.x - 6.0f, vp_pos.y), ImVec2(vp_pos.x + vp_size.x, vp_pos.y + vp_size.y), edge_color);
        fg->AddRectFilled(ImVec2(win_pos.x + win_size.x - 2.0f, win_pos.y), ImVec2(win_pos.x + win_size.x, win_pos.y + win_size.y), edge_color);
    }
    if (near_top) {
        fg->AddRectFilled(ImVec2(vp_pos.x, vp_pos.y), ImVec2(vp_pos.x + vp_size.x, vp_pos.y + 6.0f), edge_color);
        fg->AddRectFilled(ImVec2(win_pos.x, win_pos.y), ImVec2(win_pos.x + win_size.x, win_pos.y + 2.0f), edge_color);
    }
    if (near_bottom) {
        fg->AddRectFilled(ImVec2(vp_pos.x, vp_pos.y + vp_size.y - 6.0f), ImVec2(vp_pos.x + vp_size.x, vp_pos.y + vp_size.y), edge_color);
        fg->AddRectFilled(ImVec2(win_pos.x, win_pos.y + win_size.y - 2.0f), ImVec2(win_pos.x + win_size.x, win_pos.y + win_size.y), edge_color);
    }

    if (ImGui::BeginTable("titlebar", 2, ImGuiTableFlags_SizingStretchProp)) {
        ImGui::TableSetupColumn("Title", ImGuiTableColumnFlags_WidthStretch);
        ImGui::TableSetupColumn("Actions", ImGuiTableColumnFlags_WidthFixed);
        ImGui::TableNextRow();
        ImGui::TableSetColumnIndex(0);
        ImGui::TextUnformatted(g_state.title.c_str());
        ImGui::TableSetColumnIndex(1);
        if (ImGui::SmallButton(g_state.pinned ? "Pinned" : "Pin")) {
            g_state.pinned = !g_state.pinned;
            update_hint_default();
        }
        ImGui::SameLine();
        if (ImGui::SmallButton(g_state.free_control ? "Mouse On" : "Mouse Off")) {
            g_state.free_control = !g_state.free_control;
            update_hint_default();
            val payload = val::object();
            payload.set("enabled", g_state.free_control);
            post_nui("cq-admin:cb:toggleFreeControl", payload);
        }
        ImGui::EndTable();
    }

    ImGui::Separator();

    const float footer_height = ImGui::GetFrameHeightWithSpacing() + 8.0f;
    if (ImGui::BeginChild("body", ImVec2(0, -footer_height), false)) {
        if (ImGui::BeginChild("sidebar", ImVec2(280, 0), true)) {
            ImGui::SetNextItemWidth(-1.0f);
            if (g_state.search.capacity() < 64) g_state.search.reserve(64);
            InputTextWithHintString("##search", "Search", &g_state.search);
            if (g_state.just_opened) {
                ImGui::SetKeyboardFocusHere(-1);
                g_state.just_opened = false;
            }
            if (ImGui::Button("Collapse all")) {
                std::vector<std::string> ids;
                val globals = g_state.data["globalGroups"];
                if (is_array(globals)) {
                    const int len = globals["length"].as<int>();
                    for (int i = 0; i < len; ++i) collect_group_ids(globals[i], ids);
                }
                val effects = g_state.data["effects"];
                if (is_array(effects)) {
                    const int len = effects["length"].as<int>();
                    for (int i = 0; i < len; ++i) {
                        val fx = effects[i];
                        if (get_string(fx, "id", "") != g_state.selected_effect_id) continue;
                        val groups = fx["groups"];
                        if (is_array(groups)) {
                            const int glen = groups["length"].as<int>();
                            for (int g = 0; g < glen; ++g) collect_group_ids(groups[g], ids);
                        }
                    }
                }
                bool all_collapsed = !ids.empty();
                for (const auto& id : ids) {
                    if (g_state.collapsed.find(id) == g_state.collapsed.end()) {
                        all_collapsed = false;
                        break;
                    }
                }
                if (all_collapsed) {
                    for (const auto& id : ids) g_state.collapsed.erase(id);
                } else {
                    for (const auto& id : ids) g_state.collapsed.insert(id);
                }
            }
            ImGui::Separator();
            render_effect_list();
        }
        ImGui::EndChild();

        ImGui::SameLine();

        if (ImGui::BeginChild("detail", ImVec2(0, 0), true)) {
            render_detail_panel();
        }
        ImGui::EndChild();
    }
    ImGui::EndChild();

    ImGui::Separator();
    if (ImGui::Button("Reload")) {
        post_nui("cq-admin:cb:reload", val::object());
    }
    ImGui::SameLine();
    ImGui::TextDisabled("%s", g_state.hint.c_str());

    ImGui::End();

    if (alpha_pushed) {
        ImGui::PopStyleVar();
    }

    if (ImGui::IsKeyPressed(ImGuiKey_Escape) && g_state.visible && !g_state.pinned) {
        post_nui("cq-admin:cb:closeMenu", val::object());
        g_state.visible = false;
    }
}

static void apply_style() {
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding = 3.0f;
    style.FrameRounding = 3.0f;
    style.ScrollbarRounding = 3.0f;
    style.GrabRounding = 3.0f;
    style.WindowBorderSize = 1.0f;
    style.FrameBorderSize = 1.0f;

    ImVec4* colors = style.Colors;
    colors[ImGuiCol_WindowBg] = ImVec4(0.08f, 0.08f, 0.08f, 0.94f);
    colors[ImGuiCol_Border] = ImVec4(0.35f, 0.35f, 0.40f, 0.50f);
    colors[ImGuiCol_FrameBg] = ImVec4(0.16f, 0.16f, 0.16f, 0.54f);
    colors[ImGuiCol_FrameBgHovered] = ImVec4(0.22f, 0.22f, 0.22f, 0.70f);
    colors[ImGuiCol_FrameBgActive] = ImVec4(0.20f, 0.45f, 0.78f, 0.45f);
    colors[ImGuiCol_TitleBg] = ImVec4(0.06f, 0.06f, 0.06f, 0.94f);
    colors[ImGuiCol_TitleBgActive] = ImVec4(0.12f, 0.12f, 0.12f, 0.94f);
    colors[ImGuiCol_Button] = ImVec4(0.16f, 0.16f, 0.16f, 0.70f);
    colors[ImGuiCol_ButtonHovered] = ImVec4(0.22f, 0.22f, 0.22f, 0.90f);
    colors[ImGuiCol_ButtonActive] = ImVec4(0.20f, 0.45f, 0.78f, 0.65f);
    colors[ImGuiCol_Header] = ImVec4(0.20f, 0.45f, 0.78f, 0.35f);
    colors[ImGuiCol_HeaderHovered] = ImVec4(0.20f, 0.45f, 0.78f, 0.80f);
    colors[ImGuiCol_HeaderActive] = ImVec4(0.20f, 0.45f, 0.78f, 1.00f);
}

static void main_loop() {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    render_ui();

    ImGui::Render();
    int display_w, display_h;
    glfwGetFramebufferSize(g_window, &display_w, &display_h);
    glViewport(0, 0, display_w, display_h);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    glfwSwapBuffers(g_window);
    glfwPollEvents();
}

static void set_data(val data) {
    g_state.data = data;
    g_state.title = get_string(data, "title", "Menu");
    val values = data["values"];
    if (is_object(values)) {
        val keys = val::global("Object").call<val>("keys", values);
        const int len = keys["length"].as<int>();
        for (int i = 0; i < len; ++i) {
            const std::string key = keys[i].as<std::string>();
            g_state.values[key] = val_to_value(values[key]);
        }
    }
    init_defaults_from_data();
    maybe_select_default_effect();
}

static void set_visible(bool visible) {
    g_state.visible = visible;
    g_state.just_opened = visible;
    g_state.free_control = false;
    update_hint_default();
}

static void set_free_control(bool enabled) {
    g_state.free_control = enabled;
    update_hint_default();
}

static void set_hint(const std::string& text) {
    if (!text.empty()) {
        g_state.hint = text;
    } else {
        update_hint_default();
    }
}

int main() {
    if (!glfwInit()) return 1;
    const char* glsl_version = "#version 300 es";
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    g_window = glfwCreateWindow(1280, 720, "cq-admin", nullptr, nullptr);
    if (g_window == nullptr) return 1;
    glfwMakeContextCurrent(g_window);
    glfwSwapInterval(1);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.IniFilename = nullptr;
    io.LogFilename = nullptr;

    ImFontConfig font_cfg;
    font_cfg.SizePixels = 13.0f;
    font_cfg.OversampleH = 1;
    font_cfg.OversampleV = 1;
    font_cfg.PixelSnapH = true;
    io.Fonts->AddFontDefault(&font_cfg);

    apply_style();

    ImGui_ImplGlfw_InitForOpenGL(g_window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);

    emscripten_set_main_loop(main_loop, 0, true);
    return 0;
}

EMSCRIPTEN_BINDINGS(cq_admin_imgui) {
    emscripten::function("cq_set_data", &set_data);
    emscripten::function("cq_set_visible", &set_visible);
    emscripten::function("cq_set_free_control", &set_free_control);
    emscripten::function("cq_set_hint", &set_hint);
}
