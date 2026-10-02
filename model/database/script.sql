-- ================================================================
-- NEXUS RH - Banco de Dados (versão revisada e semântica)
-- MySQL 8.0+
--
-- PADRÃO DE NOMES DAS CONSTRAINTS (leia o nome e entenda a regra):
--   unico_...              -> restrição de unicidade (UNIQUE)
--   chave_estrangeira_...  -> relacionamento entre tabelas (FOREIGN KEY)
--   verificacao_...        -> regra de validação (CHECK)
--   indice_...             -> índice de desempenho (INDEX)
--
-- ATENÇÃO:
-- Este script recria o banco do zero. NÃO execute em um banco que
-- contenha dados que você queira preservar.
-- ================================================================

CREATE DATABASE db_tcc_rh
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE db_tcc_rh;


-- ================================================================
-- 1. TABELAS BASE
-- ================================================================

CREATE TABLE tbl_nivel_acesso (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    status TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT unico_nivel_acesso_nome UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE tbl_menu (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    icone VARCHAR(150),
    rota VARCHAR(255) NOT NULL,
    ordem INT NOT NULL DEFAULT 0,

    CONSTRAINT unico_menu_nome UNIQUE (nome)
) ENGINE=InnoDB;

CREATE TABLE tbl_cargo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    descricao VARCHAR(255),
    status TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT unico_cargo_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE tbl_setor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    status TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT unico_setor_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE tbl_jornada_escala (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    status TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;


CREATE TABLE tbl_beneficio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    status TINYINT(1) NOT NULL DEFAULT 1,
    disponibilidade VARCHAR(45) NOT NULL DEFAULT 'TODOS',
    
        CONSTRAINT verificacao_beneficio_disponibilidade
        CHECK (disponibilidade IN ('TODOS', 'SETOR', 'CARGO'))
) ENGINE=InnoDB;

CREATE TABLE tbl_pesquisa (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    anonimo TINYINT(1) NOT NULL DEFAULT 0,
    status TINYINT(1) NOT NULL DEFAULT 1,
    publico_selecionado VARCHAR(45) NOT NULL,
    
    CONSTRAINT verificacao_pesquisa_publico_selecionado
    CHECK (publico_selecionado IN ('TODOS', 'SETOR', 'CARGO')),

    CONSTRAINT verificacao_pesquisa_data_fim_maior_ou_igual_data_inicio
        CHECK (data_fim >= data_inicio)
) ENGINE=InnoDB;

CREATE TABLE tbl_avaliacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    anonimo TINYINT(1) NOT NULL DEFAULT 0,
    status TINYINT(1) NOT NULL DEFAULT 1,
    publico_selecionado VARCHAR(45),
    
    CONSTRAINT verificacao_avaliacao_publico_selecionado
    CHECK (publico_selecionado IN ('TODOS', 'SETOR', 'CARGO')),

    CONSTRAINT verificacao_avaliacao_data_fim_maior_ou_igual_data_inicio
        CHECK (data_fim >= data_inicio)
) ENGINE=InnoDB;

CREATE TABLE tbl_psicossocial_fator (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT unico_psicossocial_fator_nome UNIQUE (nome)
) ENGINE=InnoDB;


-- ================================================================
-- 2. JORNADA, ACESSO E COLABORADOR
-- ================================================================

CREATE TABLE tbl_dia_semana (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_jornada_escala INT NOT NULL,
    dia_semana VARCHAR(25) NOT NULL,
    dia_sigla VARCHAR(5) NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT unico_dia_da_semana_por_jornada_escala
        UNIQUE (id_jornada_escala, dia_semana),

    CONSTRAINT chave_estrangeira_dia_semana_jornada_escala
        FOREIGN KEY (id_jornada_escala)
        REFERENCES tbl_jornada_escala(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_nivel_menu (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_nivel_acesso INT NOT NULL,
    id_menu INT NOT NULL,

    CONSTRAINT unico_menu_por_nivel_acesso
        UNIQUE (id_nivel_acesso, id_menu),

    CONSTRAINT chave_estrangeira_nivel_menu_nivel_acesso
        FOREIGN KEY (id_nivel_acesso)
        REFERENCES tbl_nivel_acesso(id),

    CONSTRAINT chave_estrangeira_nivel_menu_menu
        FOREIGN KEY (id_menu)
        REFERENCES tbl_menu(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_colaborador (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_setor INT NOT NULL,
    id_cargo INT NOT NULL,
    id_jornada_escala INT NOT NULL,

    matricula VARCHAR(12) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    cpf VARCHAR(20) NOT NULL,
    data_nascimento DATE,
    email VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    data_admissao DATE NOT NULL,
    data_desligamento DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'Ativo',
    tipo_vinculo ENUM('CLT', 'PJ', 'ESTÁGIO', 'JOVEM APRENDIZ', 'TEMPORARIO'),

    CONSTRAINT unico_colaborador_matricula UNIQUE (matricula),
    CONSTRAINT unico_colaborador_cpf UNIQUE (cpf),
    CONSTRAINT unico_colaborador_email UNIQUE (email),
    
    CONSTRAINT verificacao_colaborador_status
    CHECK (status IN ('Ativo', 'Inativo')),

    CONSTRAINT verificacao_colaborador_desligamento_nulo_ou_apos_admissao
        CHECK (
            data_desligamento IS NULL
            OR data_desligamento >= data_admissao
        ),

    CONSTRAINT chave_estrangeira_colaborador_setor
        FOREIGN KEY (id_setor)
        REFERENCES tbl_setor(id),

    CONSTRAINT chave_estrangeira_colaborador_cargo
        FOREIGN KEY (id_cargo)
        REFERENCES tbl_cargo(id),

    CONSTRAINT chave_estrangeira_colaborador_jornada_escala
        FOREIGN KEY (id_jornada_escala)
        REFERENCES tbl_jornada_escala(id)

) ENGINE=InnoDB;

-- ================================================================
-- 3. BENEFÍCIOS
-- ================================================================

CREATE TABLE tbl_beneficio_cargo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_beneficio INT NOT NULL,
    id_cargo INT NOT NULL,

    CONSTRAINT unico_beneficio_por_cargo
        UNIQUE (id_beneficio, id_cargo),

    CONSTRAINT chave_estrangeira_beneficio_cargo_beneficio
        FOREIGN KEY (id_beneficio)
        REFERENCES tbl_beneficio(id),

    CONSTRAINT chave_estrangeira_beneficio_cargo_cargo
        FOREIGN KEY (id_cargo)
        REFERENCES tbl_cargo(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_beneficio_setor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_beneficio INT NOT NULL,
    id_setor INT NOT NULL,

    CONSTRAINT unico_beneficio_por_setor
        UNIQUE (id_beneficio, id_setor),

    CONSTRAINT chave_estrangeira_beneficio_setor_beneficio
        FOREIGN KEY (id_beneficio)
        REFERENCES tbl_beneficio(id),

    CONSTRAINT chave_estrangeira_beneficio_setor_setor
        FOREIGN KEY (id_setor)
        REFERENCES tbl_setor(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_beneficio_colaborador (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_beneficio INT NOT NULL,
    id_colaborador INT NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE,
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT verificacao_beneficio_colaborador_data_fim_nula_ou_apos_inicio
        CHECK (data_fim IS NULL OR data_fim >= data_inicio),

    CONSTRAINT chave_estrangeira_beneficio_colaborador_beneficio
        FOREIGN KEY (id_beneficio)
        REFERENCES tbl_beneficio(id),

    CONSTRAINT chave_estrangeira_beneficio_colaborador_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)
) ENGINE=InnoDB;

-- ================================================================
-- 4. PESQUISAS
-- ================================================================

CREATE TABLE tbl_pergunta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pesquisa INT NOT NULL,
    enunciado TEXT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    ordem INT NOT NULL DEFAULT 0,
    obrigatorio TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT unico_ordem_da_pergunta_por_pesquisa
        UNIQUE (id_pesquisa, ordem),

    CONSTRAINT chave_estrangeira_pergunta_pesquisa
        FOREIGN KEY (id_pesquisa)
        REFERENCES tbl_pesquisa(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_pesquisa_cargo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pesquisa INT NOT NULL,
    id_cargo INT NOT NULL,

    CONSTRAINT unico_cargo_por_pesquisa
        UNIQUE (id_pesquisa, id_cargo),

    CONSTRAINT chave_estrangeira_pesquisa_cargo_pesquisa
        FOREIGN KEY (id_pesquisa)
        REFERENCES tbl_pesquisa(id),

    CONSTRAINT chave_estrangeira_pesquisa_cargo_cargo
        FOREIGN KEY (id_cargo)
        REFERENCES tbl_cargo(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_pesquisa_setor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pesquisa INT NOT NULL,
    id_setor INT NOT NULL,

    CONSTRAINT unico_setor_por_pesquisa
        UNIQUE (id_pesquisa, id_setor),

    CONSTRAINT chave_estrangeira_pesquisa_setor_pesquisa
        FOREIGN KEY (id_pesquisa)
        REFERENCES tbl_pesquisa(id),

    CONSTRAINT chave_estrangeira_pesquisa_setor_setor
        FOREIGN KEY (id_setor)
        REFERENCES tbl_setor(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_participacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pesquisa INT NOT NULL,
    id_colaborador INT NOT NULL,
    status TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT unico_participacao_do_colaborador_por_pesquisa
        UNIQUE (id_pesquisa, id_colaborador),

    CONSTRAINT chave_estrangeira_participacao_pesquisa
        FOREIGN KEY (id_pesquisa)
        REFERENCES tbl_pesquisa(id),

    CONSTRAINT chave_estrangeira_participacao_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_resposta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_participacao INT NOT NULL,
    id_pergunta INT NOT NULL,
    valor TEXT,

    CONSTRAINT unico_resposta_por_participacao_e_pergunta
        UNIQUE (id_participacao, id_pergunta),

    CONSTRAINT chave_estrangeira_resposta_participacao
        FOREIGN KEY (id_participacao)
        REFERENCES tbl_participacao(id),

    CONSTRAINT chave_estrangeira_resposta_pergunta
        FOREIGN KEY (id_pergunta)
        REFERENCES tbl_pergunta(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_pesquisa_resultado (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_pergunta INT NOT NULL,
    id_pesquisa INT NOT NULL,
    valor_resposta VARCHAR(255) NOT NULL,
    quantidade_resposta INT NOT NULL DEFAULT 0,
    percentual DECIMAL(5,2) NOT NULL,

    CONSTRAINT unico_resultado_por_pergunta_pesquisa_e_valor_resposta
        UNIQUE (id_pergunta, id_pesquisa, valor_resposta),

    CONSTRAINT verificacao_pesquisa_resultado_percentual_entre_0_e_100
        CHECK (percentual >= 0 AND percentual <= 100),

    CONSTRAINT chave_estrangeira_pesquisa_resultado_pergunta
        FOREIGN KEY (id_pergunta)
        REFERENCES tbl_pergunta(id),

    CONSTRAINT chave_estrangeira_pesquisa_resultado_pesquisa
        FOREIGN KEY (id_pesquisa)
        REFERENCES tbl_pesquisa(id)
) ENGINE=InnoDB;

-- ================================================================
-- 5. AVALIAÇÕES / RISCOS PSICOSSOCIAIS
-- ================================================================

CREATE TABLE tbl_avaliacao_cargo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_avaliacao INT NOT NULL,
    id_cargo INT NOT NULL,

    CONSTRAINT unico_cargo_por_avaliacao
        UNIQUE (id_avaliacao, id_cargo),

    CONSTRAINT chave_estrangeira_avaliacao_cargo_avaliacao
        FOREIGN KEY (id_avaliacao)
        REFERENCES tbl_avaliacao(id),

    CONSTRAINT chave_estrangeira_avaliacao_cargo_cargo
        FOREIGN KEY (id_cargo)
        REFERENCES tbl_cargo(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_avaliacao_setor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_avaliacao INT NOT NULL,
    id_setor INT NOT NULL,

    CONSTRAINT unico_setor_por_avaliacao
        UNIQUE (id_avaliacao, id_setor),

    CONSTRAINT chave_estrangeira_avaliacao_setor_avaliacao
        FOREIGN KEY (id_avaliacao)
        REFERENCES tbl_avaliacao(id),

    CONSTRAINT chave_estrangeira_avaliacao_setor_setor
        FOREIGN KEY (id_setor)
        REFERENCES tbl_setor(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_avaliacao_fator (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_avaliacao INT NOT NULL,
    id_psicossocial_fator INT NOT NULL,

    CONSTRAINT unico_fator_psicossocial_por_avaliacao
        UNIQUE (id_avaliacao, id_psicossocial_fator),

    CONSTRAINT chave_estrangeira_avaliacao_fator_avaliacao
        FOREIGN KEY (id_avaliacao)
        REFERENCES tbl_avaliacao(id),

    CONSTRAINT chave_estrangeira_avaliacao_fator_psicossocial_fator
        FOREIGN KEY (id_psicossocial_fator)
        REFERENCES tbl_psicossocial_fator(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_avaliacao_pergunta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_avaliacao INT NOT NULL,
    id_psicossocial_fator INT,
    enunciado VARCHAR(255) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    ordem INT NOT NULL DEFAULT 0,
    obrigatorio TINYINT(1) NOT NULL DEFAULT 0,
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT unico_ordem_da_pergunta_por_avaliacao
        UNIQUE (id_avaliacao, ordem),

    CONSTRAINT chave_estrangeira_avaliacao_pergunta_avaliacao
        FOREIGN KEY (id_avaliacao)
        REFERENCES tbl_avaliacao(id),

    CONSTRAINT chave_estrangeira_avaliacao_pergunta_psicossocial_fator
        FOREIGN KEY (id_psicossocial_fator)
        REFERENCES tbl_psicossocial_fator(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_avaliacao_participacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_avaliacao INT NOT NULL,
    id_colaborador INT NOT NULL,
    status TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT unico_participacao_do_colaborador_por_avaliacao
        UNIQUE (id_avaliacao, id_colaborador),

    CONSTRAINT chave_estrangeira_avaliacao_participacao_avaliacao
        FOREIGN KEY (id_avaliacao)
        REFERENCES tbl_avaliacao(id),

    CONSTRAINT chave_estrangeira_avaliacao_participacao_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_avaliacao_resposta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_avaliacao_participacao INT NOT NULL,
    id_avaliacao_pergunta INT NOT NULL,
    valor TEXT,

    CONSTRAINT unico_resposta_por_participacao_e_pergunta_da_avaliacao
        UNIQUE (id_avaliacao_participacao, id_avaliacao_pergunta),

    CONSTRAINT chave_estrangeira_avaliacao_resposta_participacao
        FOREIGN KEY (id_avaliacao_participacao)
        REFERENCES tbl_avaliacao_participacao(id),

    CONSTRAINT chave_estrangeira_avaliacao_resposta_pergunta
        FOREIGN KEY (id_avaliacao_pergunta)
        REFERENCES tbl_avaliacao_pergunta(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_avaliacao_resultado (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_avaliacao INT NOT NULL,
    id_avaliacao_pergunta INT NOT NULL,
    valor_medio DECIMAL(5,2),
    quantidade_resposta INT NOT NULL DEFAULT 0,

    CONSTRAINT unico_resultado_por_avaliacao_e_pergunta
        UNIQUE (id_avaliacao, id_avaliacao_pergunta),

    CONSTRAINT chave_estrangeira_avaliacao_resultado_avaliacao
        FOREIGN KEY (id_avaliacao)
        REFERENCES tbl_avaliacao(id),

    CONSTRAINT chave_estrangeira_avaliacao_resultado_pergunta
        FOREIGN KEY (id_avaliacao_pergunta)
        REFERENCES tbl_avaliacao_pergunta(id)
) ENGINE=InnoDB;

-- O motor de regras trabalha sobre o fator psicossocial.
CREATE TABLE motor_regras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_psicossocial_fator INT NOT NULL,
    operador VARCHAR(5) NOT NULL,
    valor_referencial DECIMAL(4,2) NOT NULL,
    classificacao VARCHAR(20) NOT NULL,
    acao VARCHAR(255) NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chave_estrangeira_motor_regras_psicossocial_fator
        FOREIGN KEY (id_psicossocial_fator)
        REFERENCES tbl_psicossocial_fator(id),

    CONSTRAINT verificacao_motor_regras_operador_permitido
        CHECK (operador IN ('=', '>', '<', '>=', '<=', '<>'))
) ENGINE=InnoDB;

-- ================================================================
-- 6. USUÁRIOS / DOCUMENTOS / FÉRIAS / NOTIFICAÇÕES
-- ================================================================

CREATE TABLE tbl_usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_colaborador INT NOT NULL,
    id_nivel_acesso INT NOT NULL,
    login VARCHAR(255) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    
	CONSTRAINT unico_usuario_colaborador UNIQUE (id_colaborador),

    CONSTRAINT unico_usuario_login UNIQUE (login),

    CONSTRAINT chave_estrangeira_usuario_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id),

    CONSTRAINT chave_estrangeira_usuario_nivel_acesso
        FOREIGN KEY (id_nivel_acesso)
        REFERENCES tbl_nivel_acesso(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_documentos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_colaborador INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    tipo_documento ENUM('Contrato', 'Termo', 'Aditivo Contratual', 'Comunicação', 'Recibo', 'Avaliação', 'Documento', 'Política', 'Advertência', 'Rescisão', 'Outros') NOT NULL,
    caminho_arquivo VARCHAR(500) NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chave_estrangeira_documentos_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)

) ENGINE=InnoDB;

CREATE TABLE tbl_ferias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_colaborador INT NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    quantidade_dias INT NOT NULL,
    status VARCHAR(35) NOT NULL DEFAULT 'Pendente',
    observacao VARCHAR(255),

    CONSTRAINT verificacao_ferias_data_fim_maior_ou_igual_data_inicio
        CHECK (data_fim >= data_inicio),

    CONSTRAINT verificacao_ferias_quantidade_dias_maior_que_zero
        CHECK (quantidade_dias > 0),
        
            CONSTRAINT verificacao_ferias_status
        CHECK (status IN (
            'Pendente',
            'Aprovado pelo Gestor',
            'Recusado pelo Gestor',
            'Aprovado pelo RH',
            'Recusado pelo RH'
        )),

    CONSTRAINT chave_estrangeira_ferias_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_notificacao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_colaborador INT NOT NULL,
    tipo_origem VARCHAR(45),
    titulo VARCHAR(150) NOT NULL,
    mensagem TEXT,

    CONSTRAINT chave_estrangeira_notificacao_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)
) ENGINE=InnoDB;

-- ================================================================
-- 7. FEEDBACK
-- ================================================================

-- O feedback é destinado a um colaborador.
-- O autor é identificado pelo usuário autenticado,
-- cujo nível de acesso pode ser Gestor.
CREATE TABLE tbl_feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_colaborador INT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    descricao TEXT,
    data_feedback DATE NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chave_estrangeira_feedback_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_resposta_feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_feedback INT NOT NULL,
    id_colaborador INT NOT NULL,
    descricao TEXT NOT NULL,
    data_resposta DATE NOT NULL DEFAULT (CURRENT_DATE),
    ativo TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT unico_resposta_por_feedback_e_colaborador
        UNIQUE (id_feedback, id_colaborador),

    CONSTRAINT chave_estrangeira_resposta_feedback_feedback
        FOREIGN KEY (id_feedback)
        REFERENCES tbl_feedback(id),

    CONSTRAINT chave_estrangeira_resposta_feedback_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id)
) ENGINE=InnoDB;

-- ================================================================
-- 8. PLANO DE AÇÃO
-- ================================================================

CREATE TABLE tbl_plano_acao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_colaborador INT,
    id_setor INT NOT NULL,
    id_psicossocial_fator INT,
    titulo VARCHAR(150) NOT NULL,
    descricao TEXT NOT NULL,
    objetivo VARCHAR(500) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT verificacao_plano_acao_data_fim_maior_ou_igual_data_inicio
        CHECK (data_fim >= data_inicio),

    CONSTRAINT chave_estrangeira_plano_acao_colaborador
        FOREIGN KEY (id_colaborador)
        REFERENCES tbl_colaborador(id),

    CONSTRAINT chave_estrangeira_plano_acao_setor
        FOREIGN KEY (id_setor)
        REFERENCES tbl_setor(id),

    CONSTRAINT chave_estrangeira_plano_acao_psicossocial_fator
        FOREIGN KEY (id_psicossocial_fator)
        REFERENCES tbl_psicossocial_fator(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_tarefa_plano (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_plano_acao INT NOT NULL,
    descricao VARCHAR(500) NOT NULL,
    ordem INT NOT NULL DEFAULT 0,
    status TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT unico_ordem_da_tarefa_por_plano_acao
        UNIQUE (id_plano_acao, ordem),

    CONSTRAINT chave_estrangeira_tarefa_plano_plano_acao
        FOREIGN KEY (id_plano_acao)
        REFERENCES tbl_plano_acao(id)
) ENGINE=InnoDB;

-- ================================================================
-- 9. AUDITORIA
-- ================================================================

CREATE TABLE tbl_auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    acao VARCHAR(50) NOT NULL,
    entidade VARCHAR(100) NOT NULL,
    identificador_registro INT,
    descricao TEXT,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chave_estrangeira_auditoria_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES tbl_usuario(id)
) ENGINE=InnoDB;

-- ================================================================
-- INSERTS INICIAIS - TABELAS SEM CHAVE ESTRANGEIRA
-- ================================================================
-- ================================================================
-- 1. NÍVEIS DE ACESSO
-- ================================================================

INSERT INTO tbl_nivel_acesso (nome, status)
VALUES
('Colaborador', 1),
('Gestor', 1),
('RH', 1);


-- ================================================================
-- 2. MENUS
-- ================================================================

INSERT INTO tbl_menu (nome, icone, rota, ordem)
VALUES
('Início', 'home', '/inicio', 1),
('Colaboradores', 'users', '/colaboradores', 2),
('Setores e Cargos', 'building', '/setores-cargos', 3),
('Jornada e Escala', 'clock', '/jornada-escala', 4),
('Férias', 'calendar', '/ferias', 5),
('Benefícios', 'gift', '/beneficios', 6),
('Documentos', 'file-text', '/documentos', 7),
('Feedbacks', 'message-square', '/feedbacks', 8),
('Pesquisas', 'clipboard', '/pesquisas', 9),
('Indicadores', 'bar-chart', '/indicadores', 10),
('Avaliação Psicossocial', 'activity', '/avaliacao-psicossocial', 11),
('Motor de Regras', 'settings', '/motor-regras', 12),
('Planos de Ação', 'check-square', '/planos-acao', 13),
('Notificações', 'bell', '/notificacoes', 14),
('Relatórios', 'file-bar-chart', '/relatorios', 15);


-- ================================================================
-- 3. CARGOS
-- ================================================================

INSERT INTO tbl_cargo (codigo, nome, descricao, status)
VALUES
('CAR001', 'Analista de RH',
 'Responsável por atividades de recursos humanos.', 1),

('CAR002', 'Analista Administrativo',
 'Responsável por atividades administrativas.', 1),

('CAR003', 'Desenvolvedor de Sistemas',
 'Responsável pelo desenvolvimento e manutenção de sistemas.', 1),

('CAR004', 'Assistente Administrativo',
 'Auxilia nas atividades administrativas.', 1),

('CAR005', 'Gestor',
 'Responsável pela gestão de colaboradores.', 1),

('CAR006', 'Assistente de RH',
 'Auxilia nas atividades de recursos humanos.', 1),

('CAR007', 'Estagiário',
 'Atua em atividades de apoio e aprendizagem.', 1);


-- ================================================================
-- 4. SETORES
-- ================================================================

INSERT INTO tbl_setor (codigo, nome, descricao, status)
VALUES
('SET001', 'Recursos Humanos',
 'Setor responsável pela gestão de pessoas.', 1),

('SET002', 'Tecnologia da Informação',
 'Setor responsável por tecnologia e sistemas.', 1),

('SET003', 'Administrativo',
 'Setor responsável pelas atividades administrativas.', 1),

('SET004', 'Financeiro',
 'Setor responsável pelas atividades financeiras.', 1),

('SET005', 'Comercial',
 'Setor responsável pelas atividades comerciais.', 1);


-- ================================================================
-- 5. JORNADAS E ESCALAS
-- ================================================================

INSERT INTO tbl_jornada_escala
    (nome, descricao, hora_inicio, hora_fim, status)
VALUES
(
    'Administrativo - Manhã',
    'Jornada administrativa no período da manhã.',
    '08:00:00',
    '17:00:00',
    1
),

(
    'Administrativo - Tarde',
    'Jornada administrativa no período da tarde.',
    '13:00:00',
    '22:00:00',
    1
),

(
    'Comercial',
    'Jornada utilizada pela equipe comercial.',
    '09:00:00',
    '18:00:00',
    1
),

(
    'Tecnologia',
    'Jornada utilizada pela equipe de tecnologia.',
    '08:00:00',
    '17:00:00',
    1
);


-- ================================================================
-- 6. BENEFÍCIOS
-- ================================================================

INSERT INTO tbl_beneficio
    (nome, descricao, status, disponibilidade)
VALUES
(
    'Vale Alimentação',
    'Benefício destinado à alimentação do colaborador.',
    1,
    'TODOS'
),

(
    'Vale Transporte',
    'Benefício destinado ao deslocamento do colaborador.',
    1,
    'TODOS'
),

(
    'Plano de Saúde',
    'Plano de saúde disponibilizado pela empresa.',
    1,
    'TODOS'
),

(
    'Plano Odontológico',
    'Plano odontológico disponibilizado pela empresa.',
    1,
    'TODOS'
),

(
    'Auxílio Home Office',
    'Auxílio destinado aos colaboradores que trabalham em regime remoto.',
    1,
    'CARGO'
),

(
    'Gympass',
    'Benefício relacionado à atividade física e bem-estar.',
    1,
    'TODOS'
);


-- ================================================================
-- 7. PESQUISAS
-- ================================================================

INSERT INTO tbl_pesquisa
    (titulo, descricao, data_inicio, data_fim, anonimo, status, publico_selecionado)
VALUES
(
    'Pesquisa de Experiência do Colaborador',
    'Avaliação da experiência dos colaboradores na empresa.',
    '2026-10-01',
    '2026-10-31',
    1,
    1,
    'TODOS'
),

(
    'Pesquisa de Satisfação Interna',
    'Avaliação da satisfação dos colaboradores com o ambiente de trabalho.',
    '2026-11-01',
    '2026-11-30',
    1,
    1,
    'TODOS'
),

(
    'Pesquisa de Experiência - Tecnologia',
    'Avaliação da experiência dos colaboradores do setor de Tecnologia.',
    '2026-10-01',
    '2026-10-31',
    1,
    1,
    'SETOR'
);


-- ================================================================
-- 8. AVALIAÇÕES PSICOSSOCIAIS
-- ================================================================

INSERT INTO tbl_avaliacao
    (titulo, descricao, data_inicio, data_fim, anonimo, status, publico_selecionado)
VALUES
(
    'Avaliação de Fatores Psicossociais',
    'Avaliação dos fatores psicossociais relacionados ao ambiente de trabalho.',
    '2026-10-01',
    '2026-10-31',
    1,
    1,
    'TODOS'
),

(
    'Avaliação Psicossocial - Tecnologia',
    'Avaliação dos fatores psicossociais do setor de Tecnologia.',
    '2026-11-01',
    '2026-11-30',
    1,
    1,
    'SETOR'
);


-- ================================================================
-- 9. FATORES PSICOSSOCIAIS
-- ================================================================

INSERT INTO tbl_psicossocial_fator
    (nome, descricao, ativo)
VALUES
(
    'Carga de Trabalho',
    'Percepção dos colaboradores sobre a quantidade e intensidade das atividades.',
    1
),

(
    'Autonomia',
    'Percepção sobre liberdade e autonomia para realizar as atividades.',
    1
),

(
    'Relacionamento no Trabalho',
    'Percepção sobre os relacionamentos e convivência no ambiente de trabalho.',
    1
),

(
    'Apoio da Liderança',
    'Percepção sobre o suporte e acompanhamento recebido da liderança.',
    1
),

(
    'Reconhecimento',
    'Percepção sobre reconhecimento e valorização do trabalho realizado.',
    1
),

(
    'Clareza de Papéis',
    'Percepção sobre clareza das responsabilidades e expectativas do trabalho.',
    1
);

-- ================================================================
-- SELECT PARA CONFERIR TODAS AS CRIAÇÕES DAS TBL SEM ESTRANGEIRAS
-- ================================================================
SELECT * FROM tbl_nivel_acesso;
SELECT * FROM tbl_menu;
SELECT * FROM tbl_cargo;
SELECT * FROM tbl_setor;
SELECT * FROM tbl_jornada_escala;
SELECT * FROM tbl_beneficio;
SELECT * FROM tbl_pesquisa;
SELECT * FROM tbl_avaliacao;
SELECT * FROM tbl_psicossocial_fator;

-- ================================================================
-- FIM DOS INSERTS DAS TABELAS SEM CHAVE ESTRANGEIRA
-- ================================================================

-- ================================================================
-- INICIO DOS INSERTS DAS TABELAS COM CHAVE ESTRANGEIRA
-- ================================================================




-- ================================================================
-- INICIO tbl_dia_semana
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS JORNADAS ESTÃO DISPONIVEIS EXCUTE O SELECT ABAIXO:
-- ================================================================

SELECT * FROM tbl_jornada_escala;

-- Isso testa uma jornada de segunda a sexta:
INSERT INTO tbl_dia_semana
    (id_jornada_escala, dia_semana, dia_sigla, ativo)
VALUES
(1, 'Segunda-feira', 'SEG', 1),
(1, 'Terça-feira', 'TER', 1),
(1, 'Quarta-feira', 'QUA', 1),
(1, 'Quinta-feira', 'QUI', 1),
(1, 'Sexta-feira', 'SEX', 1);

-- ================================================================
-- Isso testa uma jornada de segunda a sabado:
-- ================================================================

INSERT INTO tbl_dia_semana
    (id_jornada_escala, dia_semana, dia_sigla, ativo)
VALUES
(2, 'Segunda-feira', 'SEG', 1),
(2, 'Terça-feira', 'TER', 1),
(2, 'Quarta-feira', 'QUA', 1),
(2, 'Quinta-feira', 'QUI', 1),
(2, 'Sexta-feira', 'SEX', 1),
(2, 'Sábado', 'SAB', 1);

-- =============================
-- Isso testa uma jornada que funciona todos os dias:
-- =============================

INSERT INTO tbl_dia_semana
    (id_jornada_escala, dia_semana, dia_sigla, ativo)
VALUES
(3, 'Domingo', 'DOM', 1),
(3, 'Segunda-feira', 'SEG', 1),
(3, 'Terça-feira', 'TER', 1),
(3, 'Quarta-feira', 'QUA', 1),
(3, 'Quinta-feira', 'QUI', 1),
(3, 'Sexta-feira', 'SEX', 1),
(3, 'Sábado', 'SAB', 1);

-- =============================
-- Isso permite desativar um dia sem apagar o registro:
-- =============================

INSERT INTO tbl_dia_semana
    (id_jornada_escala, dia_semana, dia_sigla, ativo)
VALUES
(4, 'Sábado', 'SAB', 0);

-- =============================
-- CONFERIR TUDO:
-- =============================
SELECT * 
FROM tbl_dia_semana
ORDER BY id_jornada_escala, id;

-- ================================================================
-- FIM tbl_dia_semana
-- ================================================================






-- ================================================================
-- INICIO tbl_nivel_menu
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS NÍVEIS DE ACESSO ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_nivel_acesso;

-- ================================================================
-- VERIFICAR QUAIS MENUS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_menu;

-- ================================================================
-- Isso testa os menus disponíveis para o COLABORADOR:
-- ================================================================

INSERT INTO tbl_nivel_menu
    (id_nivel_acesso, id_menu)
VALUES
(1, 1),  -- Início
(1, 5),  -- Férias
(1, 6),  -- Benefícios
(1, 7),  -- Documentos
(1, 9),  -- Pesquisas
(1, 14); -- Notificações

-- ================================================================
-- Isso testa os menus disponíveis para o GESTOR:
-- ================================================================

INSERT INTO tbl_nivel_menu
    (id_nivel_acesso, id_menu)
VALUES
(2, 1),  -- Início
(2, 2),  -- Colaboradores
(2, 5),  -- Férias
(2, 6),  -- Benefícios
(2, 7),  -- Documentos
(2, 8),  -- Feedbacks
(2, 9),  -- Pesquisas
(2, 10), -- Indicadores
(2, 11), -- Avaliação Psicossocial
(2, 14); -- Notificações

-- ================================================================
-- Isso testa todos os menus disponíveis para o RH:
-- ================================================================

INSERT INTO tbl_nivel_menu
    (id_nivel_acesso, id_menu)
VALUES
(3, 1),  -- Início
(3, 2),  -- Colaboradores
(3, 3),  -- Setores e Cargos
(3, 4),  -- Jornada e Escala
(3, 5),  -- Férias
(3, 6),  -- Benefícios
(3, 7),  -- Documentos
(3, 8),  -- Feedbacks
(3, 9),  -- Pesquisas
(3, 10), -- Indicadores
(3, 11), -- Avaliação Psicossocial
(3, 12), -- Motor de Regras
(3, 13), -- Planos de Ação
(3, 14), -- Notificações
(3, 15); -- Relatórios

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_nivel_menu.id,
    tbl_nivel_acesso.nome AS nivel_acesso,
    tbl_menu.nome AS menu
FROM tbl_nivel_menu
INNER JOIN tbl_nivel_acesso
    ON tbl_nivel_menu.id_nivel_acesso = tbl_nivel_acesso.id
INNER JOIN tbl_menu
    ON tbl_nivel_menu.id_menu = tbl_menu.id
ORDER BY tbl_nivel_menu.id_nivel_acesso, tbl_menu.ordem;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cadastrar o mesmo menu
-- duas vezes para o mesmo nível de acesso(TIRE O COMENTARIO PRA TESTAR):

 -- INSERT INTO tbl_nivel_menu (id_nivel_acesso, id_menu) VALUES (1, 1);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um nível de acesso inexistente (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_nivel_menu (id_nivel_acesso, id_menu) VALUES (999, 1);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um menu inexistente (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_nivel_menu (id_nivel_acesso, id_menu) VALUES (1, 999);

-- ================================================================
-- FIM tbl_nivel_menu
-- ================================================================





-- ================================================================
-- INICIO tbl_colaborador
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS SETORES ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_setor;

-- ================================================================
-- VERIFICAR QUAIS CARGOS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_cargo;

-- ================================================================
-- VERIFICAR QUAIS JORNADAS E ESCALAS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_jornada_escala;

-- ================================================================
-- Isso testa um colaborador comum do setor de Tecnologia:
-- ================================================================

INSERT INTO tbl_colaborador
    (id_setor, id_cargo, id_jornada_escala, matricula, nome,
     cpf, data_nascimento, email, telefone, data_admissao,
     data_desligamento, status, tipo_vinculo)
VALUES
(2, 3, 4, 'MAT001', 'João da Silva',
 '11111111111', '1998-05-10', 'joao.silva@email.com',
 '11999990001', '2025-01-15', NULL, 'Ativo', 'CLT');

-- ================================================================
-- Isso testa um colaborador do setor de RH:
-- ================================================================

INSERT INTO tbl_colaborador
    (id_setor, id_cargo, id_jornada_escala, matricula, nome,
     cpf, data_nascimento, email, telefone, data_admissao,
     data_desligamento, status, tipo_vinculo)
VALUES
(1, 1, 1, 'MAT002', 'Maria Oliveira',
 '22222222222', '1995-08-20', 'maria.oliveira@email.com',
 '11999990002', '2024-03-01', NULL, 'Ativo', 'CLT');

-- ================================================================
-- Isso testa um GESTOR:
-- O gestor continua sendo um colaborador normal.
-- A diferença de acesso será definida posteriormente
-- na tbl_usuario através do nível de acesso.
-- ================================================================

INSERT INTO tbl_colaborador
    (id_setor, id_cargo, id_jornada_escala, matricula, nome,
     cpf, data_nascimento, email, telefone, data_admissao,
     data_desligamento, status, tipo_vinculo)
VALUES
(3, 5, 1, 'MAT003', 'Carlos Santos',
 '33333333333', '1990-02-15', 'carlos.santos@email.com',
 '11999990003', '2023-06-10', NULL, 'Ativo', 'CLT');

-- ================================================================
-- Isso testa um colaborador com vínculo de ESTÁGIO:
-- ================================================================

INSERT INTO tbl_colaborador
    (id_setor, id_cargo, id_jornada_escala, matricula, nome,
     cpf, data_nascimento, email, telefone, data_admissao,
     data_desligamento, status, tipo_vinculo)
VALUES
(2, 7, 4, 'MAT004', 'Ana Costa',
 '44444444444', '2005-11-30', 'ana.costa@email.com',
 '11999990004', '2026-02-01', NULL, 'Ativo', 'ESTAGIO');

-- ================================================================
-- Isso testa um colaborador INATIVO:
-- O colaborador permanece cadastrado, mas seu status fica inativo.
-- ================================================================

INSERT INTO tbl_colaborador
    (id_setor, id_cargo, id_jornada_escala, matricula, nome,
     cpf, data_nascimento, email, telefone, data_admissao,
     data_desligamento, status, tipo_vinculo)
VALUES
(4, 2, 1, 'MAT005', 'Pedro Almeida',
 '55555555555', '1988-04-25', 'pedro.almeida@email.com',
 '11999990005', '2022-08-01', '2026-09-15', 'Inativo', 'CLT');

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT *
FROM tbl_colaborador
ORDER BY id;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir matrícula duplicada
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (2, 3, 4, 'MAT001', 'Outro Colaborador',
--  '66666666666', '1999-01-10', 'outro@email.com',
--  '11999990006', '2026-01-01', NULL, 'Ativo', 'CLT');

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir CPF duplicado
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (2, 3, 4, 'MAT006', 'Outro Colaborador',
--  '11111111111', '1999-01-10', 'outro2@email.com',
--  '11999990007', '2026-01-01', NULL, 'Ativo', 'CLT');

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir e-mail duplicado
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (2, 3, 4, 'MAT006', 'Outro Colaborador',
--  '66666666666', '1999-01-10', 'joao.silva@email.com',
--  '11999990008', '2026-01-01', NULL, 'Ativo', 'CLT');

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir setor inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (999, 3, 4, 'MAT006', 'Outro Colaborador',
--  '66666666666', '1999-01-10', 'outro3@email.com',
--  '11999990009', '2026-01-01', NULL, 'Ativo', 'CLT');

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cargo inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (2, 999, 4, 'MAT006', 'Outro Colaborador',
--  '66666666666', '1999-01-10', 'outro4@email.com',
--  '11999990010', '2026-01-01', NULL, 'Ativo', 'CLT');

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir jornada inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (2, 3, 999, 'MAT006', 'Outro Colaborador',
--  '66666666666', '1999-01-10', 'outro5@email.com',
--  '11999990011', '2026-01-01', NULL, 'Ativo', 'CLT');

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma data de desligamento
-- anterior à data de admissão
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (2, 3, 4, 'MAT006', 'Outro Colaborador',
--  '66666666666', '1999-01-10', 'outro6@email.com',
--  '11999990012', '2026-06-01', '2026-05-01', 'Inativo', 'CLT');

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um status diferente de Ativo ou Inativo
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_colaborador
--     (id_setor, id_cargo, id_jornada_escala, matricula, nome,
--      cpf, data_nascimento, email, telefone, data_admissao,
--      data_desligamento, status, tipo_vinculo)
-- VALUES
-- (2, 3, 4, 'MAT006', 'Outro Colaborador',
--  '66666666666', '1999-01-10', 'outro7@email.com',
--  '11999990013', '2026-01-01', NULL, 'Afastado', 'CLT');

-- ================================================================
-- FIM tbl_colaborador
-- ================================================================





-- ================================================================
-- INICIO tbl_beneficio_cargo
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS BENEFÍCIOS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_beneficio;

-- ================================================================
-- VERIFICAR QUAIS CARGOS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_cargo;

-- ================================================================
-- Isso testa o benefício Auxílio Home Office
-- disponibilizado para o cargo Desenvolvedor de Sistemas:
-- ================================================================

INSERT INTO tbl_beneficio_cargo
    (id_beneficio, id_cargo)
VALUES
(5, 3);

-- ================================================================
-- Isso testa o mesmo benefício disponibilizado
-- para o cargo Analista de RH:
-- ================================================================

INSERT INTO tbl_beneficio_cargo
    (id_beneficio, id_cargo)
VALUES
(5, 1);

-- ================================================================
-- Isso testa o mesmo benefício disponibilizado
-- para o cargo Gestor:
-- ================================================================

INSERT INTO tbl_beneficio_cargo
    (id_beneficio, id_cargo)
VALUES
(5, 5);

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_beneficio_cargo.id,
    tbl_beneficio.nome AS beneficio,
    tbl_cargo.nome AS cargo
FROM tbl_beneficio_cargo
INNER JOIN tbl_beneficio
    ON tbl_beneficio_cargo.id_beneficio = tbl_beneficio.id
INNER JOIN tbl_cargo
    ON tbl_beneficio_cargo.id_cargo = tbl_cargo.id
ORDER BY tbl_beneficio_cargo.id;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cadastrar o mesmo benefício
-- duas vezes para o mesmo cargo
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_cargo
--     (id_beneficio, id_cargo)
-- VALUES
-- (5, 3);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um benefício inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_cargo
--     (id_beneficio, id_cargo)
-- VALUES
-- (999, 3);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um cargo inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_cargo
--     (id_beneficio, id_cargo)
-- VALUES
-- (5, 999);

-- ================================================================
-- FIM tbl_beneficio_cargo
-- ================================================================




-- ================================================================
-- INICIO tbl_beneficio_setor
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS BENEFÍCIOS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_beneficio;

-- ================================================================
-- VERIFICAR QUAIS SETORES ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_setor;

-- ================================================================
-- Isso testa o benefício Auxílio Home Office
-- disponibilizado para o setor de Tecnologia da Informação:
-- ================================================================

INSERT INTO tbl_beneficio_setor
    (id_beneficio, id_setor)
VALUES
(5, 2);

-- ================================================================
-- Isso testa o mesmo benefício disponibilizado
-- para o setor Administrativo:
-- ================================================================

INSERT INTO tbl_beneficio_setor
    (id_beneficio, id_setor)
VALUES
(5, 3);

-- ================================================================
-- Isso testa o mesmo benefício disponibilizado
-- para o setor Comercial:
-- ================================================================

INSERT INTO tbl_beneficio_setor
    (id_beneficio, id_setor)
VALUES
(5, 5);

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_beneficio_setor.id,
    tbl_beneficio.nome AS beneficio,
    tbl_setor.nome AS setor
FROM tbl_beneficio_setor
INNER JOIN tbl_beneficio
    ON tbl_beneficio_setor.id_beneficio = tbl_beneficio.id
INNER JOIN tbl_setor
    ON tbl_beneficio_setor.id_setor = tbl_setor.id
ORDER BY tbl_beneficio_setor.id;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cadastrar o mesmo benefício
-- duas vezes para o mesmo setor
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_setor
--     (id_beneficio, id_setor)
-- VALUES
-- (5, 2);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um benefício inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_setor
--     (id_beneficio, id_setor)
-- VALUES
-- (999, 2);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um setor inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_setor
--     (id_beneficio, id_setor)
-- VALUES
-- (5, 999);

-- ================================================================
-- FIM tbl_beneficio_setor
-- ================================================================




-- ================================================================
-- INICIO tbl_beneficio_colaborador
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS BENEFÍCIOS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_beneficio;

-- ================================================================
-- VERIFICAR QUAIS COLABORADORES ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_colaborador;

-- ================================================================
-- Isso testa um benefício ativo para o João:
-- ================================================================

INSERT INTO tbl_beneficio_colaborador
    (id_beneficio, id_colaborador, data_inicio, data_fim, ativo)
VALUES
(1, 1, '2026-01-01', NULL, 1);

-- ================================================================
-- Isso testa um benefício com data de início e data de fim:
-- ================================================================

INSERT INTO tbl_beneficio_colaborador
    (id_beneficio, id_colaborador, data_inicio, data_fim, ativo)
VALUES
(2, 1, '2026-01-01', '2026-12-31', 1);

-- ================================================================
-- Isso testa outro benefício para um colaborador diferente:
-- ================================================================

INSERT INTO tbl_beneficio_colaborador
    (id_beneficio, id_colaborador, data_inicio, data_fim, ativo)
VALUES
(3, 2, '2026-03-01', NULL, 1);

-- ================================================================
-- Isso permite manter o histórico de um benefício desativado
-- sem apagar o registro:
-- ================================================================

INSERT INTO tbl_beneficio_colaborador
    (id_beneficio, id_colaborador, data_inicio, data_fim, ativo)
VALUES
(4, 3, '2025-01-01', '2026-06-30', 0);

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_beneficio_colaborador.id,
    tbl_beneficio.nome AS beneficio,
    tbl_colaborador.nome AS colaborador,
    tbl_beneficio_colaborador.data_inicio,
    tbl_beneficio_colaborador.data_fim,
    tbl_beneficio_colaborador.ativo
FROM tbl_beneficio_colaborador
INNER JOIN tbl_beneficio
    ON tbl_beneficio_colaborador.id_beneficio = tbl_beneficio.id
INNER JOIN tbl_colaborador
    ON tbl_beneficio_colaborador.id_colaborador = tbl_colaborador.id
ORDER BY tbl_beneficio_colaborador.id;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma data de fim
-- anterior à data de início
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_colaborador
--     (id_beneficio, id_colaborador, data_inicio, data_fim, ativo)
-- VALUES
-- (5, 1, '2026-10-01', '2026-09-01', 1);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um benefício inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_colaborador
--     (id_beneficio, id_colaborador, data_inicio, data_fim, ativo)
-- VALUES
-- (999, 1, '2026-01-01', NULL, 1);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_beneficio_colaborador
--     (id_beneficio, id_colaborador, data_inicio, data_fim, ativo)
-- VALUES
-- (1, 999, '2026-01-01', NULL, 1);

-- ================================================================
-- FIM tbl_beneficio_colaborador
-- ================================================================






-- ================================================================
-- INICIO tbl_pergunta
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS PESQUISAS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_pesquisa;

-- ================================================================
-- Isso testa perguntas para a primeira pesquisa:
-- ================================================================

INSERT INTO tbl_pergunta
    (id_pesquisa, enunciado, tipo, ordem, obrigatorio)
VALUES
(1, 'Como você avalia sua satisfação com o ambiente de trabalho?', 'ESCALA', 1, 1),
(1, 'Você considera adequada a comunicação interna da empresa?', 'ESCALA', 2, 1),
(1, 'O que poderia ser melhorado no ambiente de trabalho?', 'TEXTO', 3, 0);

-- ================================================================
-- Isso testa perguntas para uma pesquisa diferente:
-- ================================================================

INSERT INTO tbl_pergunta
    (id_pesquisa, enunciado, tipo, ordem, obrigatorio)
VALUES
(2, 'Você considera adequada sua carga de trabalho?', 'ESCALA', 1, 1),
(2, 'Você recebe suporte adequado da sua liderança?', 'ESCALA', 2, 1);

-- ================================================================
-- Isso testa uma pergunta opcional:
-- ================================================================

INSERT INTO tbl_pergunta
    (id_pesquisa, enunciado, tipo, ordem, obrigatorio)
VALUES
(3, 'Gostaria de deixar algum comentário sobre a pesquisa?', 'TEXTO', 1, 0);

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_pergunta.id,
    tbl_pesquisa.titulo AS pesquisa,
    tbl_pergunta.enunciado,
    tbl_pergunta.tipo,
    tbl_pergunta.ordem,
    tbl_pergunta.obrigatorio
FROM tbl_pergunta
INNER JOIN tbl_pesquisa
    ON tbl_pergunta.id_pesquisa = tbl_pesquisa.id
ORDER BY tbl_pergunta.id_pesquisa, tbl_pergunta.ordem;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir duas perguntas com a mesma ordem
-- dentro da mesma pesquisa
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pergunta
--     (id_pesquisa, enunciado, tipo, ordem, obrigatorio)
-- VALUES
-- (1, 'Outra pergunta para teste', 'TEXTO', 1, 0);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pesquisa inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pergunta
--     (id_pesquisa, enunciado, tipo, ordem, obrigatorio)
-- VALUES
-- (999, 'Pergunta para teste', 'TEXTO', 1, 0);

-- ================================================================
-- FIM tbl_pergunta
-- ================================================================






-- ================================================================
-- INICIO tbl_pesquisa_cargo
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS PESQUISAS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_pesquisa;

-- ================================================================
-- VERIFICAR QUAIS CARGOS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_cargo;

-- ================================================================
-- Isso testa a pesquisa direcionada para o cargo
-- Desenvolvedor de Sistemas:
-- ================================================================

INSERT INTO tbl_pesquisa_cargo
    (id_pesquisa, id_cargo)
VALUES
(2, 3);

-- ================================================================
-- Isso testa a mesma pesquisa direcionada para o cargo
-- Analista de RH:
-- ================================================================

INSERT INTO tbl_pesquisa_cargo
    (id_pesquisa, id_cargo)
VALUES
(2, 1);

-- ================================================================
-- Isso testa uma pesquisa diferente direcionada para o cargo
-- Gestor:
-- ================================================================

INSERT INTO tbl_pesquisa_cargo
    (id_pesquisa, id_cargo)
VALUES
(3, 5);

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_pesquisa_cargo.id,
    tbl_pesquisa.titulo AS pesquisa,
    tbl_cargo.nome AS cargo
FROM tbl_pesquisa_cargo
INNER JOIN tbl_pesquisa
    ON tbl_pesquisa_cargo.id_pesquisa = tbl_pesquisa.id
INNER JOIN tbl_cargo
    ON tbl_pesquisa_cargo.id_cargo = tbl_cargo.id
ORDER BY tbl_pesquisa_cargo.id;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cadastrar a mesma pesquisa
-- duas vezes para o mesmo cargo
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pesquisa_cargo
--     (id_pesquisa, id_cargo)
-- VALUES
-- (2, 3);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pesquisa inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pesquisa_cargo
--     (id_pesquisa, id_cargo)
-- VALUES
-- (999, 3);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um cargo inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pesquisa_cargo
--     (id_pesquisa, id_cargo)
-- VALUES
-- (2, 999);

-- ================================================================
-- FIM tbl_pesquisa_cargo
-- ================================================================


-- ================================================================
-- INICIO tbl_pesquisa_setor
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS PESQUISAS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_pesquisa;

-- ================================================================
-- VERIFICAR QUAIS SETORES ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_setor;

-- ================================================================
-- Isso testa a pesquisa direcionada para o setor
-- de Tecnologia da Informação:
-- ================================================================

INSERT INTO tbl_pesquisa_setor
    (id_pesquisa, id_setor)
VALUES
(2, 2);

-- ================================================================
-- Isso testa a mesma pesquisa direcionada para o setor
-- Administrativo:
-- ================================================================

INSERT INTO tbl_pesquisa_setor
    (id_pesquisa, id_setor)
VALUES
(2, 3);

-- ================================================================
-- Isso testa uma pesquisa diferente direcionada para o setor
-- Comercial:
-- ================================================================

INSERT INTO tbl_pesquisa_setor
    (id_pesquisa, id_setor)
VALUES
(3, 5);

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_pesquisa_setor.id,
    tbl_pesquisa.titulo AS pesquisa,
    tbl_setor.nome AS setor
FROM tbl_pesquisa_setor
INNER JOIN tbl_pesquisa
    ON tbl_pesquisa_setor.id_pesquisa = tbl_pesquisa.id
INNER JOIN tbl_setor
    ON tbl_pesquisa_setor.id_setor = tbl_setor.id
ORDER BY tbl_pesquisa_setor.id;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cadastrar a mesma pesquisa
-- duas vezes para o mesmo setor
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pesquisa_setor
--     (id_pesquisa, id_setor)
-- VALUES
-- (2, 2);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pesquisa inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pesquisa_setor
--     (id_pesquisa, id_setor)
-- VALUES
-- (999, 2);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um setor inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_pesquisa_setor
--     (id_pesquisa, id_setor)
-- VALUES
-- (2, 999);

-- ================================================================
-- FIM tbl_pesquisa_setor
-- ================================================================





-- ================================================================
-- INICIO tbl_participacao
-- ================================================================

-- ================================================================
-- VERIFICAR QUAIS PESQUISAS ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_pesquisa;

-- ================================================================
-- VERIFICAR QUAIS COLABORADORES ESTÃO DISPONÍVEIS:
-- ================================================================

SELECT * FROM tbl_colaborador;

-- ================================================================
-- Isso testa uma participação PENDENTE:
-- 0 = Pendente
-- ================================================================

INSERT INTO tbl_participacao
    (id_pesquisa, id_colaborador, status)
VALUES
(1, 1, 0);

-- ================================================================
-- Isso testa uma participação CONCLUÍDA:
-- 1 = Concluída
-- ================================================================

INSERT INTO tbl_participacao
    (id_pesquisa, id_colaborador, status)
VALUES
(1, 2, 1);

-- ================================================================
-- Isso testa outro colaborador participando da mesma pesquisa:
-- ================================================================

INSERT INTO tbl_participacao
    (id_pesquisa, id_colaborador, status)
VALUES
(1, 3, 1);

-- ================================================================
-- Isso testa um colaborador participando de outra pesquisa:
-- ================================================================

INSERT INTO tbl_participacao
    (id_pesquisa, id_colaborador, status)
VALUES
(2, 1, 0);

-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_participacao.id,
    tbl_pesquisa.titulo AS pesquisa,
    tbl_colaborador.nome AS colaborador,
    tbl_participacao.status
FROM tbl_participacao
INNER JOIN tbl_pesquisa
    ON tbl_participacao.id_pesquisa = tbl_pesquisa.id
INNER JOIN tbl_colaborador
    ON tbl_participacao.id_colaborador = tbl_colaborador.id
ORDER BY tbl_participacao.id;

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir o mesmo colaborador
-- participar duas vezes da mesma pesquisa
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_participacao
--     (id_pesquisa, id_colaborador, status)
-- VALUES
-- (1, 1, 0);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pesquisa inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_participacao
--     (id_pesquisa, id_colaborador, status)
-- VALUES
-- (999, 1, 0);

-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador inexistente
-- (TIRE O COMENTARIO PRA TESTAR):

-- INSERT INTO tbl_participacao
--     (id_pesquisa, id_colaborador, status)
-- VALUES
-- (1, 999, 0);

-- ================================================================
-- FIM tbl_participacao
-- ================================================================






-- ================================================================
-- INICIO tbl_resposta
-- ================================================================


-- ================================================================
-- VERIFICAR PARTICIPAÇÕES E PERGUNTAS DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_participacao;

SELECT * FROM tbl_pergunta;


-- ================================================================
-- ISSO TESTA:
-- Inserção de respostas para diferentes participações.
-- O campo valor é TEXT, então pode armazenar tanto respostas
-- numéricas da escala quanto respostas de texto.
-- ================================================================

-- Participação 1 pertence à pesquisa 1
INSERT INTO tbl_resposta
    (id_participacao, id_pergunta, valor)
VALUES
    (1, 1, '5');

INSERT INTO tbl_resposta
    (id_participacao, id_pergunta, valor)
VALUES
    (1, 2, '4');

INSERT INTO tbl_resposta
    (id_participacao, id_pergunta, valor)
VALUES
    (1, 3, 'O ambiente de trabalho é muito agradável.');


-- Participação 2 também pertence à pesquisa 1
INSERT INTO tbl_resposta
    (id_participacao, id_pergunta, valor)
VALUES
    (2, 1, '4');

INSERT INTO tbl_resposta
    (id_participacao, id_pergunta, valor)
VALUES
    (2, 2, '5');


-- Participação 4 pertence à pesquisa 2
INSERT INTO tbl_resposta
    (id_participacao, id_pergunta, valor)
VALUES
    (4, 4, '3');

INSERT INTO tbl_resposta
    (id_participacao, id_pergunta, valor)
VALUES
    (4, 5, 'Gostaria de receber mais feedbacks sobre meu trabalho.');


-- ================================================================
-- CONFERIR TUDO:
-- Mostra a participação, colaborador, pesquisa, pergunta e resposta.
-- ================================================================

SELECT
    tbl_resposta.id,
    tbl_resposta.id_participacao,
    tbl_participacao.id_pesquisa,
    tbl_pesquisa.titulo AS pesquisa,
    tbl_participacao.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_resposta.id_pergunta,
    tbl_pergunta.enunciado AS pergunta,
    tbl_resposta.valor AS resposta
FROM tbl_resposta
INNER JOIN tbl_participacao
    ON tbl_resposta.id_participacao = tbl_participacao.id
INNER JOIN tbl_pesquisa
    ON tbl_participacao.id_pesquisa = tbl_pesquisa.id
INNER JOIN tbl_colaborador
    ON tbl_participacao.id_colaborador = tbl_colaborador.id
INNER JOIN tbl_pergunta
    ON tbl_resposta.id_pergunta = tbl_pergunta.id
ORDER BY tbl_resposta.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir duas respostas para a mesma
-- pergunta dentro da mesma participação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_resposta
--     (id_participacao, id_pergunta, valor)
-- VALUES
--     (1, 1, '3');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma participação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_resposta
--     (id_participacao, id_pergunta, valor)
-- VALUES
--     (999, 1, '5');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pergunta que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_resposta
--     (id_participacao, id_pergunta, valor)
-- VALUES
--     (1, 999, '5');


-- ================================================================
-- FIM tbl_resposta
-- ================================================================






-- ================================================================
-- INICIO tbl_pesquisa_resultado
-- ================================================================


-- ================================================================
-- VERIFICAR PESQUISAS E PERGUNTAS DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_pesquisa;

SELECT * FROM tbl_pergunta;


-- ================================================================
-- ISSO TESTA:
-- Inserção dos resultados consolidados de uma pesquisa.
--
-- valor_resposta = valor da resposta
-- quantidade_resposta = quantidade de pessoas que escolheram o valor
-- percentual = percentual correspondente
--
-- Exemplo:
-- 2 pessoas responderam 5 = 40%
-- ================================================================

INSERT INTO tbl_pesquisa_resultado
    (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
VALUES
    (1, 1, '5', 2, 40.00);

INSERT INTO tbl_pesquisa_resultado
    (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
VALUES
    (1, 1, '4', 3, 60.00);

INSERT INTO tbl_pesquisa_resultado
    (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
VALUES
    (2, 1, '5', 4, 80.00);

INSERT INTO tbl_pesquisa_resultado
    (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
VALUES
    (2, 1, '4', 1, 20.00);

INSERT INTO tbl_pesquisa_resultado
    (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
VALUES
    (3, 1, 'O ambiente de trabalho é muito agradável.', 3, 60.00);


-- ================================================================
-- CONFERIR TUDO:
-- Mostra o resultado consolidado junto com a pesquisa e a pergunta.
-- ================================================================

SELECT
    tbl_pesquisa_resultado.id,
    tbl_pesquisa_resultado.id_pesquisa,
    tbl_pesquisa.titulo AS pesquisa,
    tbl_pesquisa_resultado.id_pergunta,
    tbl_pergunta.enunciado AS pergunta,
    tbl_pesquisa_resultado.valor_resposta,
    tbl_pesquisa_resultado.quantidade_resposta,
    tbl_pesquisa_resultado.percentual
FROM tbl_pesquisa_resultado
INNER JOIN tbl_pesquisa
    ON tbl_pesquisa_resultado.id_pesquisa = tbl_pesquisa.id
INNER JOIN tbl_pergunta
    ON tbl_pesquisa_resultado.id_pergunta = tbl_pergunta.id
ORDER BY
    tbl_pesquisa_resultado.id_pesquisa,
    tbl_pesquisa_resultado.id_pergunta,
    tbl_pesquisa_resultado.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cadastrar novamente o mesmo resultado
-- para a mesma pergunta, pesquisa e valor de resposta.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_pesquisa_resultado
--     (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (1, 1, '5', 1, 20.00);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pergunta que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_pesquisa_resultado
--     (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (999, 1, '5', 1, 20.00);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pesquisa que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_pesquisa_resultado
--     (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (1, 999, '5', 1, 20.00);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir percentual menor que 0 ou maior que 100.
-- Deve dar erro de CHECK.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_pesquisa_resultado
--     (id_pergunta, id_pesquisa, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (1, 1, '3', 1, 150.00);


-- ================================================================
-- FIM tbl_pesquisa_resultado
-- ================================================================






-- ================================================================
-- INICIO tbl_avaliacao_cargo
-- ================================================================


-- ================================================================
-- VERIFICAR AVALIAÇÕES E CARGOS DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_avaliacao;

SELECT * FROM tbl_cargo;


-- ================================================================
-- ISSO TESTA:
-- Vinculação de avaliações a cargos específicos.
-- ================================================================

INSERT INTO tbl_avaliacao_cargo
    (id_avaliacao, id_cargo)
VALUES
    (2, 3);

INSERT INTO tbl_avaliacao_cargo
    (id_avaliacao, id_cargo)
VALUES
    (2, 1);

INSERT INTO tbl_avaliacao_cargo
    (id_avaliacao, id_cargo)
VALUES
    (1, 5);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_avaliacao_cargo.id,
    tbl_avaliacao_cargo.id_avaliacao,
    tbl_avaliacao.titulo AS avaliacao,
    tbl_avaliacao_cargo.id_cargo,
    tbl_cargo.codigo,
    tbl_cargo.nome AS cargo
FROM tbl_avaliacao_cargo
INNER JOIN tbl_avaliacao
    ON tbl_avaliacao_cargo.id_avaliacao = tbl_avaliacao.id
INNER JOIN tbl_cargo
    ON tbl_avaliacao_cargo.id_cargo = tbl_cargo.id
ORDER BY
    tbl_avaliacao_cargo.id_avaliacao,
    tbl_avaliacao_cargo.id_cargo;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir o mesmo cargo vinculado duas vezes
-- à mesma avaliação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_cargo
--     (id_avaliacao, id_cargo)
-- VALUES
--     (2, 3);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma avaliação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_cargo
--     (id_avaliacao, id_cargo)
-- VALUES
--     (999, 3);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um cargo que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_cargo
--     (id_avaliacao, id_cargo)
-- VALUES
--     (2, 999);


-- ================================================================
-- FIM tbl_avaliacao_cargo
-- ================================================================






-- ================================================================
-- INICIO tbl_avaliacao_setor
-- ================================================================


-- ================================================================
-- VERIFICAR AVALIAÇÕES E SETORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_avaliacao;

SELECT * FROM tbl_setor;


-- ================================================================
-- ISSO TESTA:
-- Vinculação de avaliações a setores específicos.
-- ================================================================

INSERT INTO tbl_avaliacao_setor
    (id_avaliacao, id_setor)
VALUES
    (2, 2);

INSERT INTO tbl_avaliacao_setor
    (id_avaliacao, id_setor)
VALUES
    (2, 3);

INSERT INTO tbl_avaliacao_setor
    (id_avaliacao, id_setor)
VALUES
    (1, 5);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_avaliacao_setor.id,
    tbl_avaliacao_setor.id_avaliacao,
    tbl_avaliacao.titulo AS avaliacao,
    tbl_avaliacao_setor.id_setor,
    tbl_setor.codigo,
    tbl_setor.nome AS setor
FROM tbl_avaliacao_setor
INNER JOIN tbl_avaliacao
    ON tbl_avaliacao_setor.id_avaliacao = tbl_avaliacao.id
INNER JOIN tbl_setor
    ON tbl_avaliacao_setor.id_setor = tbl_setor.id
ORDER BY
    tbl_avaliacao_setor.id_avaliacao,
    tbl_avaliacao_setor.id_setor;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir o mesmo setor vinculado duas vezes
-- à mesma avaliação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_setor
--     (id_avaliacao, id_setor)
-- VALUES
--     (2, 2);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma avaliação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_setor
--     (id_avaliacao, id_setor)
-- VALUES
--     (999, 2);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um setor que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_setor
--     (id_avaliacao, id_setor)
-- VALUES
--     (2, 999);


-- ================================================================
-- FIM tbl_avaliacao_setor
-- ================================================================





-- ================================================================
-- INICIO tbl_avaliacao_fator
-- ================================================================


-- ================================================================
-- VERIFICAR AVALIAÇÕES E FATORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_avaliacao;

SELECT * FROM tbl_psicossocial_fator;


-- ================================================================
-- ISSO TESTA:
-- Vinculação de fatores psicossociais às avaliações.
-- ================================================================

INSERT INTO tbl_avaliacao_fator
    (id_avaliacao, id_psicossocial_fator)
VALUES
    (1, 1);

INSERT INTO tbl_avaliacao_fator
    (id_avaliacao, id_psicossocial_fator)
VALUES
    (1, 2);

INSERT INTO tbl_avaliacao_fator
    (id_avaliacao, id_psicossocial_fator)
VALUES
    (1, 3);

INSERT INTO tbl_avaliacao_fator
    (id_avaliacao, id_psicossocial_fator)
VALUES
    (2, 4);

INSERT INTO tbl_avaliacao_fator
    (id_avaliacao, id_psicossocial_fator)
VALUES
    (2, 5);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_avaliacao_fator.id,
    tbl_avaliacao_fator.id_avaliacao,
    tbl_avaliacao.titulo AS avaliacao,
    tbl_avaliacao_fator.id_psicossocial_fator,
    tbl_psicossocial_fator.nome AS fator,
    tbl_psicossocial_fator.descricao
FROM tbl_avaliacao_fator
INNER JOIN tbl_avaliacao
    ON tbl_avaliacao_fator.id_avaliacao = tbl_avaliacao.id
INNER JOIN tbl_psicossocial_fator
    ON tbl_avaliacao_fator.id_psicossocial_fator = tbl_psicossocial_fator.id
ORDER BY
    tbl_avaliacao_fator.id_avaliacao,
    tbl_avaliacao_fator.id_psicossocial_fator;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir o mesmo fator vinculado duas vezes
-- à mesma avaliação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_fator
--     (id_avaliacao, id_psicossocial_fator)
-- VALUES
--     (1, 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma avaliação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_fator
--     (id_avaliacao, id_psicossocial_fator)
-- VALUES
--     (999, 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um fator psicossocial que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_fator
--     (id_avaliacao, id_psicossocial_fator)
-- VALUES
--     (1, 999);


-- ================================================================
-- FIM tbl_avaliacao_fator
-- ================================================================






-- ================================================================
-- INICIO tbl_avaliacao_pergunta
-- ================================================================


-- ================================================================
-- VERIFICAR AVALIAÇÕES, FATORES E PERGUNTAS DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_avaliacao;

SELECT * FROM tbl_psicossocial_fator;

SELECT * FROM tbl_avaliacao_fator;


-- ================================================================
-- ISSO TESTA:
-- Cadastro das perguntas de uma avaliação psicossocial.
--
-- Cada pergunta é vinculada a uma avaliação e a um fator
-- psicossocial.
-- ================================================================

INSERT INTO tbl_avaliacao_pergunta
    (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
VALUES
    (1, 1, 'A quantidade de trabalho é adequada para o tempo disponível.', 'ESCALA', 1, 1);

INSERT INTO tbl_avaliacao_pergunta
    (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
VALUES
    (1, 1, 'Consigo realizar minhas atividades sem excesso de trabalho.', 'ESCALA', 2, 1);

INSERT INTO tbl_avaliacao_pergunta
    (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
VALUES
    (1, 2, 'Tenho autonomia para tomar decisões relacionadas ao meu trabalho.', 'ESCALA', 3, 1);

INSERT INTO tbl_avaliacao_pergunta
    (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
VALUES
    (1, 3, 'Existe um bom relacionamento entre os colaboradores.', 'ESCALA', 4, 1);

INSERT INTO tbl_avaliacao_pergunta
    (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
VALUES
    (2, 4, 'Recebo apoio da minha liderança quando necessário.', 'ESCALA', 1, 1);

INSERT INTO tbl_avaliacao_pergunta
    (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
VALUES
    (2, 5, 'Meu trabalho é reconhecido pela organização.', 'ESCALA', 2, 1);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_avaliacao_pergunta.id,
    tbl_avaliacao_pergunta.id_avaliacao,
    tbl_avaliacao.titulo AS avaliacao,
    tbl_avaliacao_pergunta.id_psicossocial_fator,
    tbl_psicossocial_fator.nome AS fator,
    tbl_avaliacao_pergunta.enunciado AS pergunta,
    tbl_avaliacao_pergunta.tipo,
    tbl_avaliacao_pergunta.ordem,
    tbl_avaliacao_pergunta.obrigatorio
FROM tbl_avaliacao_pergunta
INNER JOIN tbl_avaliacao
    ON tbl_avaliacao_pergunta.id_avaliacao = tbl_avaliacao.id
INNER JOIN tbl_psicossocial_fator
    ON tbl_avaliacao_pergunta.id_psicossocial_fator = tbl_psicossocial_fator.id
ORDER BY
    tbl_avaliacao_pergunta.id_avaliacao,
    tbl_avaliacao_pergunta.ordem;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir duas perguntas com a mesma ordem
-- dentro da mesma avaliação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_pergunta
--     (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
-- VALUES
--     (1, 1, 'Pergunta duplicada para teste.', 'ESCALA', 1, 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma avaliação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_pergunta
--     (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
-- VALUES
--     (999, 1, 'Pergunta para teste.', 'ESCALA', 10, 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um fator psicossocial que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_pergunta
--     (id_avaliacao, id_psicossocial_fator, enunciado, tipo, ordem, obrigatorio)
-- VALUES
--     (1, 999, 'Pergunta para teste.', 'ESCALA', 10, 1);


-- ================================================================
-- FIM tbl_avaliacao_pergunta
-- ================================================================







-- ================================================================
-- INICIO tbl_avaliacao_participacao
-- ================================================================


-- ================================================================
-- VERIFICAR AVALIAÇÕES E COLABORADORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_avaliacao;

SELECT * FROM tbl_colaborador;


-- ================================================================
-- ISSO TESTA:
-- Registro dos colaboradores que participam de cada avaliação.
--
-- status:
-- 0 = Pendente
-- 1 = Concluída
-- ================================================================

INSERT INTO tbl_avaliacao_participacao
    (id_avaliacao, id_colaborador, status)
VALUES
    (1, 1, 0);

INSERT INTO tbl_avaliacao_participacao
    (id_avaliacao, id_colaborador, status)
VALUES
    (1, 2, 1);

INSERT INTO tbl_avaliacao_participacao
    (id_avaliacao, id_colaborador, status)
VALUES
    (1, 3, 1);

INSERT INTO tbl_avaliacao_participacao
    (id_avaliacao, id_colaborador, status)
VALUES
    (2, 1, 0);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_avaliacao_participacao.id,
    tbl_avaliacao_participacao.id_avaliacao,
    tbl_avaliacao.titulo AS avaliacao,
    tbl_avaliacao_participacao.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_avaliacao_participacao.status
FROM tbl_avaliacao_participacao
INNER JOIN tbl_avaliacao
    ON tbl_avaliacao_participacao.id_avaliacao = tbl_avaliacao.id
INNER JOIN tbl_colaborador
    ON tbl_avaliacao_participacao.id_colaborador = tbl_colaborador.id
ORDER BY
    tbl_avaliacao_participacao.id_avaliacao,
    tbl_avaliacao_participacao.id_colaborador;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir o mesmo colaborador participar
-- duas vezes da mesma avaliação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_participacao
--     (id_avaliacao, id_colaborador, status)
-- VALUES
--     (1, 1, 0);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma avaliação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_participacao
--     (id_avaliacao, id_colaborador, status)
-- VALUES
--     (999, 1, 0);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_participacao
--     (id_avaliacao, id_colaborador, status)
-- VALUES
--     (1, 999, 0);


-- ================================================================
-- FIM tbl_avaliacao_participacao
-- ================================================================






-- ================================================================
-- INICIO tbl_avaliacao_resposta
-- ================================================================


-- ================================================================
-- VERIFICAR PARTICIPAÇÕES E PERGUNTAS DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_avaliacao_participacao;

SELECT * FROM tbl_avaliacao_pergunta;


-- ================================================================
-- ISSO TESTA:
-- Registro das respostas dos colaboradores nas avaliações
-- psicossociais.
--
-- O campo valor é TEXT, permitindo armazenar os valores
-- das respostas da escala.
-- ================================================================

-- Participação 1 pertence à avaliação 1
INSERT INTO tbl_avaliacao_resposta
    (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
VALUES
    (1, 1, '5');

INSERT INTO tbl_avaliacao_resposta
    (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
VALUES
    (1, 2, '4');

INSERT INTO tbl_avaliacao_resposta
    (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
VALUES
    (1, 3, '5');


-- Participação 2 também pertence à avaliação 1
INSERT INTO tbl_avaliacao_resposta
    (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
VALUES
    (2, 1, '4');

INSERT INTO tbl_avaliacao_resposta
    (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
VALUES
    (2, 2, '5');


-- Participação 4 pertence à avaliação 2
INSERT INTO tbl_avaliacao_resposta
    (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
VALUES
    (4, 5, '3');

INSERT INTO tbl_avaliacao_resposta
    (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
VALUES
    (4, 6, '4');


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_avaliacao_resposta.id,
    tbl_avaliacao_resposta.id_avaliacao_participacao,
    tbl_avaliacao_participacao.id_avaliacao,
    tbl_avaliacao.titulo AS avaliacao,
    tbl_avaliacao_participacao.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_avaliacao_resposta.id_avaliacao_pergunta,
    tbl_avaliacao_pergunta.enunciado AS pergunta,
    tbl_avaliacao_resposta.valor AS resposta
FROM tbl_avaliacao_resposta
INNER JOIN tbl_avaliacao_participacao
    ON tbl_avaliacao_resposta.id_avaliacao_participacao = tbl_avaliacao_participacao.id
INNER JOIN tbl_avaliacao
    ON tbl_avaliacao_participacao.id_avaliacao = tbl_avaliacao.id
INNER JOIN tbl_colaborador
    ON tbl_avaliacao_participacao.id_colaborador = tbl_colaborador.id
INNER JOIN tbl_avaliacao_pergunta
    ON tbl_avaliacao_resposta.id_avaliacao_pergunta = tbl_avaliacao_pergunta.id
ORDER BY tbl_avaliacao_resposta.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir duas respostas para a mesma
-- pergunta dentro da mesma participação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_resposta
--     (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
-- VALUES
--     (1, 1, '3');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma participação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_resposta
--     (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
-- VALUES
--     (999, 1, '5');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pergunta que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_resposta
--     (id_avaliacao_participacao, id_avaliacao_pergunta, valor)
-- VALUES
--     (1, 999, '5');


-- ================================================================
-- FIM tbl_avaliacao_resposta
-- ================================================================




-- ================================================================
-- INICIO tbl_avaliacao_resultado
-- ================================================================


-- ================================================================
-- VERIFICAR AVALIAÇÕES E PERGUNTAS DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_avaliacao;

SELECT * FROM tbl_avaliacao_pergunta;


-- ================================================================
-- ISSO TESTA:
-- Inserção dos resultados consolidados da avaliação psicossocial.
--
-- valor_resposta = valor da resposta
-- quantidade_resposta = quantidade de pessoas que escolheram o valor
-- percentual = percentual correspondente
-- ================================================================

INSERT INTO tbl_avaliacao_resultado
    (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
VALUES
    (1, 1, '5', 3, 60.00);

INSERT INTO tbl_avaliacao_resultado
    (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
VALUES
    (1, 1, '4', 2, 40.00);

INSERT INTO tbl_avaliacao_resultado
    (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
VALUES
    (2, 1, '5', 4, 80.00);

INSERT INTO tbl_avaliacao_resultado
    (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
VALUES
    (2, 1, '4', 1, 20.00);

INSERT INTO tbl_avaliacao_resultado
    (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
VALUES
    (5, 2, '3', 2, 40.00);

INSERT INTO tbl_avaliacao_resultado
    (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
VALUES
    (5, 2, '4', 3, 60.00);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_avaliacao_resultado.id,
    tbl_avaliacao_resultado.id_avaliacao,
    tbl_avaliacao.titulo AS avaliacao,
    tbl_avaliacao_resultado.id_avaliacao_pergunta,
    tbl_avaliacao_pergunta.enunciado AS pergunta,
    tbl_avaliacao_resultado.valor_resposta,
    tbl_avaliacao_resultado.quantidade_resposta,
    tbl_avaliacao_resultado.percentual
FROM tbl_avaliacao_resultado
INNER JOIN tbl_avaliacao
    ON tbl_avaliacao_resultado.id_avaliacao = tbl_avaliacao.id
INNER JOIN tbl_avaliacao_pergunta
    ON tbl_avaliacao_resultado.id_avaliacao_pergunta = tbl_avaliacao_pergunta.id
ORDER BY
    tbl_avaliacao_resultado.id_avaliacao,
    tbl_avaliacao_resultado.id_avaliacao_pergunta,
    tbl_avaliacao_resultado.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir cadastrar novamente o mesmo resultado
-- para a mesma pergunta, avaliação e valor de resposta.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_resultado
--     (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (1, 1, '5', 1, 20.00);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma pergunta que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_resultado
--     (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (999, 1, '5', 1, 20.00);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma avaliação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_resultado
--     (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (1, 999, '5', 1, 20.00);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir percentual menor que 0 ou maior que 100.
-- Deve dar erro de CHECK.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_avaliacao_resultado
--     (id_avaliacao_pergunta, id_avaliacao, valor_resposta, quantidade_resposta, percentual)
-- VALUES
--     (1, 1, '3', 1, 150.00);


-- ================================================================
-- FIM tbl_avaliacao_resultado
-- ================================================================






-- ================================================================
-- INICIO motor_regras
-- ================================================================


-- ================================================================
-- VERIFICAR FATORES PSICOSSOCIAIS DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_psicossocial_fator;


-- ================================================================
-- ISSO TESTA:
-- Cadastro de regras do Motor de Regras.
--
-- A estrutura da regra segue:
-- SE condição → ENTÃO ação
--
-- operador:
-- =  igual
-- >  maior que
-- <  menor que
-- >= maior ou igual
-- <= menor ou igual
-- <> diferente
-- ================================================================

-- Regra para carga de trabalho em situação de atenção
INSERT INTO motor_regras
    (id_psicossocial_fator, operador, valor_referencial, classificacao, acao, ativo)
VALUES
    (1, '<', 2.50, 'Atenção',
     'Notificar o RH para avaliar a carga de trabalho do setor.', 1);


-- Regra para carga de trabalho em situação de prioridade
INSERT INTO motor_regras
    (id_psicossocial_fator, operador, valor_referencial, classificacao, acao, ativo)
VALUES
    (1, '<', 2.00, 'Prioridade',
     'Criar plano de ação para tratar a carga de trabalho.', 1);


-- Regra para autonomia
INSERT INTO motor_regras
    (id_psicossocial_fator, operador, valor_referencial, classificacao, acao, ativo)
VALUES
    (2, '<', 2.50, 'Atenção',
     'Notificar o RH sobre o indicador de autonomia.', 1);


-- Regra inativa para testar o campo ativo
INSERT INTO motor_regras
    (id_psicossocial_fator, operador, valor_referencial, classificacao, acao, ativo)
VALUES
    (3, '<', 2.00, 'Prioridade',
     'Avaliar o relacionamento no trabalho.', 0);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    motor_regras.id,
    motor_regras.id_psicossocial_fator,
    tbl_psicossocial_fator.nome AS fator_psicossocial,
    motor_regras.operador,
    motor_regras.valor_referencial,
    motor_regras.classificacao,
    motor_regras.acao,
    motor_regras.ativo
FROM motor_regras
INNER JOIN tbl_psicossocial_fator
    ON motor_regras.id_psicossocial_fator = tbl_psicossocial_fator.id
ORDER BY motor_regras.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um fator psicossocial que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO motor_regras
--     (id_psicossocial_fator, operador, valor_referencial, classificacao, acao, ativo)
-- VALUES
--     (999, '<', 2.50, 'Atenção',
--      'Regra para teste.', 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um operador diferente dos permitidos.
-- Deve dar erro de CHECK.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO motor_regras
--     (id_psicossocial_fator, operador, valor_referencial, classificacao, acao, ativo)
-- VALUES
--     (1, '!=', 2.50, 'Atenção',
--      'Regra para teste.', 1);


-- ================================================================
-- FIM motor_regras
-- ================================================================






-- ================================================================
-- INICIO tbl_usuario
-- ================================================================


-- ================================================================
-- VERIFICAR COLABORADORES E NÍVEIS DE ACESSO DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_colaborador;

SELECT * FROM tbl_nivel_acesso;


-- ================================================================
-- ISSO TESTA:
-- Cadastro dos usuários que terão acesso ao sistema.
--
-- Cada usuário:
-- - pertence a um colaborador;
-- - possui um nível de acesso;
-- - possui um login;
-- - possui uma senha.
--
-- Níveis utilizados:
-- Colaborador
-- Gestor
-- RH
-- ================================================================

-- João = Colaborador
INSERT INTO tbl_usuario
    (id_colaborador, id_nivel_acesso, login, senha)
VALUES
    (1, 1, 'joao.silva', 'Senha@123');


-- Maria = RH
INSERT INTO tbl_usuario
    (id_colaborador, id_nivel_acesso, login, senha)
VALUES
    (2, 3, 'maria.rh', 'Senha@123');


-- Carlos = Gestor
INSERT INTO tbl_usuario
    (id_colaborador, id_nivel_acesso, login, senha)
VALUES
    (3, 2, 'carlos.gestor', 'Senha@123');


-- Ana = Colaborador
INSERT INTO tbl_usuario
    (id_colaborador, id_nivel_acesso, login, senha)
VALUES
    (4, 1, 'ana.estagiaria', 'Senha@123');


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_usuario.id,
    tbl_usuario.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_colaborador.matricula,
    tbl_usuario.id_nivel_acesso,
    tbl_nivel_acesso.nome AS nivel_acesso,
    tbl_usuario.login,
    tbl_usuario.senha
FROM tbl_usuario
INNER JOIN tbl_colaborador
    ON tbl_usuario.id_colaborador = tbl_colaborador.id
INNER JOIN tbl_nivel_acesso
    ON tbl_usuario.id_nivel_acesso = tbl_nivel_acesso.id
ORDER BY tbl_usuario.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir dois usuários para o mesmo colaborador.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_usuario
--     (id_colaborador, id_nivel_acesso, login, senha)
-- VALUES
--     (1, 1, 'joao.silva2', 'Senha@123');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir dois usuários com o mesmo login.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_usuario
--     (id_colaborador, id_nivel_acesso, login, senha)
-- VALUES
--     (5, 1, 'joao.silva', 'OutraSenha@123');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_usuario
--     (id_colaborador, id_nivel_acesso, login, senha)
-- VALUES
--     (999, 1, 'usuario.teste', 'Senha@123');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um nível de acesso que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_usuario
--     (id_colaborador, id_nivel_acesso, login, senha)
-- VALUES
--     (5, 999, 'usuario.teste', 'Senha@123');


-- ================================================================
-- FIM tbl_usuario
-- ================================================================





-- ================================================================
-- INICIO tbl_documentos
-- ================================================================


-- ================================================================
-- VERIFICAR COLABORADORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_colaborador;


-- ================================================================
-- ISSO TESTA:
-- Cadastro de documentos vinculados aos colaboradores.
--
-- Tipos de documento disponíveis:
-- Contrato
-- Termo
-- Aditivo Contratual
-- Comunicação
-- Recibo
-- Avaliação
-- Documento
-- Política
-- Advertência
-- Rescisão
-- Outros
-- ================================================================

INSERT INTO tbl_documentos
    (id_colaborador, nome, tipo_documento, caminho_arquivo, ativo)
VALUES
    (1, 'Contrato de Trabalho - João da Silva', 'Contrato',
     '/documentos/joao/contrato-trabalho.pdf', 1);

INSERT INTO tbl_documentos
    (id_colaborador, nome, tipo_documento, caminho_arquivo, ativo)
VALUES
    (1, 'Termo de Responsabilidade - João da Silva', 'Termo',
     '/documentos/joao/termo-responsabilidade.pdf', 1);

INSERT INTO tbl_documentos
    (id_colaborador, nome, tipo_documento, caminho_arquivo, ativo)
VALUES
    (2, 'Contrato de Trabalho - Maria da Silva', 'Contrato',
     '/documentos/maria/contrato-trabalho.pdf', 1);

INSERT INTO tbl_documentos
    (id_colaborador, nome, tipo_documento, caminho_arquivo, ativo)
VALUES
    (3, 'Avaliação de Desempenho - Carlos da Silva', 'Avaliação',
     '/documentos/carlos/avaliacao-desempenho.pdf', 1);

INSERT INTO tbl_documentos
    (id_colaborador, nome, tipo_documento, caminho_arquivo, ativo)
VALUES
    (5, 'Rescisão Contratual - Pedro da Silva', 'Rescisão',
     '/documentos/pedro/rescisao.pdf', 0);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_documentos.id,
    tbl_documentos.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_documentos.nome AS documento,
    tbl_documentos.tipo_documento,
    tbl_documentos.caminho_arquivo,
    tbl_documentos.ativo
FROM tbl_documentos
INNER JOIN tbl_colaborador
    ON tbl_documentos.id_colaborador = tbl_colaborador.id
ORDER BY tbl_documentos.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_documentos
--     (id_colaborador, nome, tipo_documento, caminho_arquivo, ativo)
-- VALUES
--     (999, 'Documento de teste', 'Documento',
--      '/documentos/teste.pdf', 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um tipo de documento que não esteja
-- definido no ENUM.
-- Deve dar erro de ENUM.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_documentos
--     (id_colaborador, nome, tipo_documento, caminho_arquivo, ativo)
-- VALUES
--     (1, 'Documento de teste', 'TipoInexistente',
--      '/documentos/teste.pdf', 1);


-- ================================================================
-- FIM tbl_documentos
-- ================================================================




-- ================================================================
-- INICIO tbl_ferias
-- ================================================================


-- ================================================================
-- VERIFICAR COLABORADORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_colaborador;


-- ================================================================
-- ISSO TESTA:
-- Cadastro de solicitações de férias.
--
-- Fluxo:
-- Colaborador solicita
-- → Gestor analisa
-- → RH faz a aprovação/recusa final
--
-- Status possíveis:
-- Pendente
-- Aprovado pelo Gestor
-- Recusado pelo Gestor
-- Aprovado pelo RH
-- Recusado pelo RH
-- ================================================================

INSERT INTO tbl_ferias
    (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
VALUES
    (1, '2026-10-12', '2026-10-21', 10, 'Pendente',
     'Solicitação de férias realizada pelo colaborador.');


INSERT INTO tbl_ferias
    (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
VALUES
    (2, '2026-11-03', '2026-11-12', 10, 'Aprovado pelo Gestor',
     'Férias aprovadas pelo gestor. Aguardando análise do RH.');


INSERT INTO tbl_ferias
    (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
VALUES
    (3, '2026-12-01', '2026-12-10', 10, 'Aprovado pelo RH',
     'Férias aprovadas pelo gestor e pelo RH.');


INSERT INTO tbl_ferias
    (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
VALUES
    (4, '2026-10-05', '2026-10-09', 5, 'Recusado pelo Gestor',
     'Período indisponível para a equipe.');


INSERT INTO tbl_ferias
    (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
VALUES
    (5, '2026-10-19', '2026-10-23', 5, 'Recusado pelo RH',
     'Período não aprovado pelo RH.');


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_ferias.id,
    tbl_ferias.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_ferias.data_inicio,
    tbl_ferias.data_fim,
    tbl_ferias.quantidade_dias,
    tbl_ferias.status,
    tbl_ferias.observacao
FROM tbl_ferias
INNER JOIN tbl_colaborador
    ON tbl_ferias.id_colaborador = tbl_colaborador.id
ORDER BY tbl_ferias.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma data final anterior à data inicial.
-- Deve dar erro de CHECK.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_ferias
--     (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
-- VALUES
--     (1, '2026-10-20', '2026-10-10', 10, 'Pendente',
--      'Teste de data inválida.');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir quantidade de dias igual a zero
-- ou negativa.
-- Deve dar erro de CHECK.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_ferias
--     (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
-- VALUES
--     (1, '2026-10-12', '2026-10-21', 0, 'Pendente',
--      'Teste de quantidade inválida.');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um status que não esteja definido.
-- Deve dar erro de CHECK.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_ferias
--     (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
-- VALUES
--     (1, '2026-10-12', '2026-10-21', 10, 'Cancelado',
--      'Teste de status inválido.');


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_ferias
--     (id_colaborador, data_inicio, data_fim, quantidade_dias, status, observacao)
-- VALUES
--     (999, '2026-10-12', '2026-10-21', 10, 'Pendente',
--      'Teste de colaborador inexistente.');


-- ================================================================
-- FIM tbl_ferias
-- ================================================================





-- ================================================================
-- INICIO tbl_notificacao
-- ================================================================


-- ================================================================
-- VERIFICAR COLABORADORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_colaborador;


-- ================================================================
-- ISSO TESTA:
-- Cadastro de notificações direcionadas aos colaboradores.
--
-- A notificação pode informar, por exemplo:
-- - aprovação ou recusa de férias;
-- - nova pesquisa disponível;
-- - novo documento;
-- - aviso do RH;
-- - atualização de solicitação.
-- ================================================================

INSERT INTO tbl_notificacao
    (id_colaborador, tipo_origem, titulo, mensagem)
VALUES
    (1, 'FERIAS',
     'Férias aprovadas',
     'Sua solicitação de férias foi aprovada pelo gestor e está aguardando análise do RH.');


INSERT INTO tbl_notificacao
    (id_colaborador, tipo_origem, titulo, mensagem)
VALUES
    (2, 'PESQUISA',
     'Nova pesquisa disponível',
     'Uma nova pesquisa de experiência está disponível para sua participação.');


INSERT INTO tbl_notificacao
    (id_colaborador, tipo_origem, titulo, mensagem)
VALUES
    (3, 'RH',
     'Comunicado do RH',
     'O RH publicou um novo comunicado para os colaboradores.');


INSERT INTO tbl_notificacao
    (id_colaborador, tipo_origem, titulo, mensagem)
VALUES
    (4, 'DOCUMENTO',
     'Novo documento disponível',
     'Um novo documento foi disponibilizado para você consultar.');


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_notificacao.id,
    tbl_notificacao.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_notificacao.tipo_origem,
    tbl_notificacao.titulo,
    tbl_notificacao.mensagem
FROM tbl_notificacao
INNER JOIN tbl_colaborador
    ON tbl_notificacao.id_colaborador = tbl_colaborador.id
ORDER BY tbl_notificacao.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_notificacao
--     (id_colaborador, tipo_origem, titulo, mensagem)
-- VALUES
--     (999, 'RH',
--      'Notificação de teste',
--      'Mensagem de teste.');


-- ================================================================
-- FIM tbl_notificacao
-- ================================================================




-- ================================================================
-- INICIO tbl_feedback
-- ================================================================


-- ================================================================
-- VERIFICAR COLABORADORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_colaborador;


-- ================================================================
-- ISSO TESTA:
-- Cadastro de feedbacks direcionados aos colaboradores.
--
-- O feedback pode ser utilizado, por exemplo, para:
-- - reconhecimento;
-- - orientação;
-- - acompanhamento;
-- - desenvolvimento.
-- ================================================================

INSERT INTO tbl_feedback
    (id_colaborador, tipo, descricao, data_feedback, ativo)
VALUES
    (1, 'Reconhecimento',
     'Demonstrou bom desempenho e colaboração nas atividades da equipe.',
     '2026-10-01', 1);


INSERT INTO tbl_feedback
    (id_colaborador, tipo, descricao, data_feedback, ativo)
VALUES
    (2, 'Orientação',
     'É necessário melhorar o acompanhamento das atividades administrativas.',
     '2026-10-02', 1);


INSERT INTO tbl_feedback
    (id_colaborador, tipo, descricao, data_feedback, ativo)
VALUES
    (3, 'Desenvolvimento',
     'Apresentou evolução na liderança e organização da equipe.',
     '2026-10-03', 1);


INSERT INTO tbl_feedback
    (id_colaborador, tipo, descricao, data_feedback, ativo)
VALUES
    (4, 'Acompanhamento',
     'Feedback realizado para acompanhar o desenvolvimento profissional.',
     '2026-10-04', 1);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_feedback.id,
    tbl_feedback.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_feedback.tipo,
    tbl_feedback.descricao,
    tbl_feedback.data_feedback,
    tbl_feedback.ativo
FROM tbl_feedback
INNER JOIN tbl_colaborador
    ON tbl_feedback.id_colaborador = tbl_colaborador.id
ORDER BY tbl_feedback.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_feedback
--     (id_colaborador, tipo, descricao, data_feedback, ativo)
-- VALUES
--     (999, 'Reconhecimento',
--      'Feedback de teste.',
--      '2026-10-05', 1);


-- ================================================================
-- FIM tbl_feedback
-- ================================================================








-- ================================================================
-- INICIO tbl_resposta_feedback
-- ================================================================


-- ================================================================
-- VERIFICAR FEEDBACKS E COLABORADORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_feedback;

SELECT * FROM tbl_colaborador;


-- ================================================================
-- ISSO TESTA:
-- Cadastro de respostas aos feedbacks.
--
-- A resposta fica vinculada:
-- - ao feedback;
-- - ao colaborador que respondeu.
-- ================================================================

INSERT INTO tbl_resposta_feedback
    (id_feedback, id_colaborador, descricao, data_resposta, ativo)
VALUES
    (1, 3,
     'Obrigado pelo reconhecimento. Vou continuar mantendo esse desempenho.',
     '2026-10-02', 1);


INSERT INTO tbl_resposta_feedback
    (id_feedback, id_colaborador, descricao, data_resposta, ativo)
VALUES
    (2, 2,
     'Entendi a orientação e vou melhorar o acompanhamento das atividades.',
     '2026-10-03', 1);


INSERT INTO tbl_resposta_feedback
    (id_feedback, id_colaborador, descricao, data_resposta, ativo)
VALUES
    (3, 3,
     'Agradeço o feedback. Vou continuar trabalhando no desenvolvimento da liderança.',
     '2026-10-04', 1);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_resposta_feedback.id,
    tbl_resposta_feedback.id_feedback,
    tbl_feedback.tipo AS tipo_feedback,
    tbl_feedback.descricao AS feedback,
    tbl_resposta_feedback.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_resposta_feedback.descricao AS resposta,
    tbl_resposta_feedback.data_resposta,
    tbl_resposta_feedback.ativo
FROM tbl_resposta_feedback
INNER JOIN tbl_feedback
    ON tbl_resposta_feedback.id_feedback = tbl_feedback.id
INNER JOIN tbl_colaborador
    ON tbl_resposta_feedback.id_colaborador = tbl_colaborador.id
ORDER BY tbl_resposta_feedback.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir o mesmo colaborador responder
-- duas vezes ao mesmo feedback.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_resposta_feedback
--     (id_feedback, id_colaborador, descricao, data_resposta, ativo)
-- VALUES
--     (1, 3,
--      'Segunda resposta para o mesmo feedback.',
--      '2026-10-05', 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um feedback que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_resposta_feedback
--     (id_feedback, id_colaborador, descricao, data_resposta, ativo)
-- VALUES
--     (999, 3,
--      'Resposta de teste.',
--      '2026-10-05', 1);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_resposta_feedback
--     (id_feedback, id_colaborador, descricao, data_resposta, ativo)
-- VALUES
--     (1, 999,
--      'Resposta de teste.',
--      '2026-10-05', 1);


-- ================================================================
-- FIM tbl_resposta_feedback
-- ================================================================





-- ================================================================
-- INICIO tbl_plano_acao
-- ================================================================


-- ================================================================
-- VERIFICAR COLABORADORES, SETORES E FATORES DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_colaborador;

SELECT * FROM tbl_setor;

SELECT * FROM tbl_psicossocial_fator;


-- ================================================================
-- ISSO TESTA:
-- Cadastro de planos de ação para tratar situações identificadas.
--
-- O plano pode ser relacionado:
-- - a um setor;
-- - a um colaborador específico;
-- - a um fator psicossocial.
--
-- id_colaborador e id_psicossocial_fator podem ser NULL.
-- O setor é obrigatório.
--
-- status:
-- 0 = Em andamento
-- 1 = Encerrado
-- ================================================================

-- Plano relacionado a um setor e fator psicossocial
INSERT INTO tbl_plano_acao
    (id_colaborador, id_setor, id_psicossocial_fator,
     titulo, descricao, objetivo, data_inicio, data_fim, status)
VALUES
    (NULL, 2, 1,
     'Redução da carga de trabalho',
     'Revisar a distribuição das atividades entre os colaboradores do setor.',
     'Reduzir a percepção de sobrecarga de trabalho.',
     '2026-10-01',
     '2026-11-30',
     0);


-- Plano relacionado a um colaborador específico
INSERT INTO tbl_plano_acao
    (id_colaborador, id_setor, id_psicossocial_fator,
     titulo, descricao, objetivo, data_inicio, data_fim, status)
VALUES
    (1, 2, 2,
     'Aumento da autonomia',
     'Definir atividades em que o colaborador possa tomar decisões de forma independente.',
     'Aumentar a autonomia nas atividades profissionais.',
     '2026-10-05',
     '2026-11-05',
     0);


-- Plano relacionado somente ao setor
INSERT INTO tbl_plano_acao
    (id_colaborador, id_setor, id_psicossocial_fator,
     titulo, descricao, objetivo, data_inicio, data_fim, status)
VALUES
    (NULL, 3, NULL,
     'Melhoria da comunicação interna',
     'Criar ações para melhorar a comunicação entre os colaboradores.',
     'Melhorar o fluxo de informações dentro do setor.',
     '2026-09-01',
     '2026-10-01',
     1);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_plano_acao.id,
    tbl_plano_acao.id_colaborador,
    tbl_colaborador.nome AS colaborador,
    tbl_plano_acao.id_setor,
    tbl_setor.nome AS setor,
    tbl_plano_acao.id_psicossocial_fator,
    tbl_psicossocial_fator.nome AS fator_psicossocial,
    tbl_plano_acao.titulo,
    tbl_plano_acao.descricao,
    tbl_plano_acao.objetivo,
    tbl_plano_acao.data_inicio,
    tbl_plano_acao.data_fim,
    tbl_plano_acao.status
FROM tbl_plano_acao
INNER JOIN tbl_setor
    ON tbl_plano_acao.id_setor = tbl_setor.id
LEFT JOIN tbl_colaborador
    ON tbl_plano_acao.id_colaborador = tbl_colaborador.id
LEFT JOIN tbl_psicossocial_fator
    ON tbl_plano_acao.id_psicossocial_fator = tbl_psicossocial_fator.id
ORDER BY tbl_plano_acao.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir uma data final anterior à data inicial.
-- Deve dar erro de CHECK.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_plano_acao
--     (id_colaborador, id_setor, id_psicossocial_fator,
--      titulo, descricao, objetivo, data_inicio, data_fim, status)
-- VALUES
--     (NULL, 2, 1,
--      'Plano inválido',
--      'Teste de data inválida.',
--      'Teste',
--      '2026-11-30',
--      '2026-10-01',
--      0);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um setor que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_plano_acao
--     (id_colaborador, id_setor, id_psicossocial_fator,
--      titulo, descricao, objetivo, data_inicio, data_fim, status)
-- VALUES
--     (NULL, 999, 1,
--      'Plano inválido',
--      'Teste de setor inexistente.',
--      'Teste',
--      '2026-10-01',
--      '2026-11-01',
--      0);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um colaborador que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_plano_acao
--     (id_colaborador, id_setor, id_psicossocial_fator,
--      titulo, descricao, objetivo, data_inicio, data_fim, status)
-- VALUES
--     (999, 2, 1,
--      'Plano inválido',
--      'Teste de colaborador inexistente.',
--      'Teste',
--      '2026-10-01',
--      '2026-11-01',
--      0);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um fator psicossocial que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_plano_acao
--     (id_colaborador, id_setor, id_psicossocial_fator,
--      titulo, descricao, objetivo, data_inicio, data_fim, status)
-- VALUES
--     (NULL, 2, 999,
--      'Plano inválido',
--      'Teste de fator inexistente.',
--      'Teste',
--      '2026-10-01',
--      '2026-11-01',
--      0);


-- ================================================================
-- FIM tbl_plano_acao
-- ================================================================





-- ================================================================
-- INICIO tbl_tarefa_plano
-- ================================================================


-- ================================================================
-- VERIFICAR PLANOS DE AÇÃO DISPONÍVEIS
-- ================================================================

SELECT * FROM tbl_plano_acao;


-- ================================================================
-- ISSO TESTA:
-- Cadastro das tarefas que pertencem a um plano de ação.
--
-- status:
-- 0 = Em andamento
-- 1 = Concluída
--
-- A ordem permite organizar a sequência das tarefas
-- dentro de cada plano.
-- ================================================================

INSERT INTO tbl_tarefa_plano
    (id_plano_acao, descricao, ordem, status)
VALUES
    (1,
     'Analisar a distribuição atual das atividades do setor.',
     1,
     0);

INSERT INTO tbl_tarefa_plano
    (id_plano_acao, descricao, ordem, status)
VALUES
    (1,
     'Redistribuir as atividades entre os colaboradores.',
     2,
     0);

INSERT INTO tbl_tarefa_plano
    (id_plano_acao, descricao, ordem, status)
VALUES
    (1,
     'Avaliar os resultados após a redistribuição.',
     3,
     1);


-- Tarefas do segundo plano
INSERT INTO tbl_tarefa_plano
    (id_plano_acao, descricao, ordem, status)
VALUES
    (2,
     'Definir atividades que poderão ser realizadas com maior autonomia.',
     1,
     1);

INSERT INTO tbl_tarefa_plano
    (id_plano_acao, descricao, ordem, status)
VALUES
    (2,
     'Acompanhar a autonomia do colaborador durante as atividades.',
     2,
     0);


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_tarefa_plano.id,
    tbl_tarefa_plano.id_plano_acao,
    tbl_plano_acao.titulo AS plano_acao,
    tbl_tarefa_plano.descricao AS tarefa,
    tbl_tarefa_plano.ordem,
    tbl_tarefa_plano.status
FROM tbl_tarefa_plano
INNER JOIN tbl_plano_acao
    ON tbl_tarefa_plano.id_plano_acao = tbl_plano_acao.id
ORDER BY
    tbl_tarefa_plano.id_plano_acao,
    tbl_tarefa_plano.ordem;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir duas tarefas com a mesma ordem
-- dentro do mesmo plano de ação.
-- Deve dar erro de UNIQUE.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_tarefa_plano
--     (id_plano_acao, descricao, ordem, status)
-- VALUES
--     (1,
--      'Tarefa com ordem duplicada.',
--      1,
--      0);


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir um plano de ação que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_tarefa_plano
--     (id_plano_acao, descricao, ordem, status)
-- VALUES
--     (999,
--      'Tarefa para plano inexistente.',
--      1,
--      0);


-- ================================================================
-- FIM tbl_tarefa_plano
-- ================================================================






-- ================================================================
-- INICIO tbl_auditoria
-- ================================================================


-- ================================================================
-- VERIFICAR USUÁRIOS DISPONÍVEIS
-- ================================================================

SELECT
    tbl_usuario.id,
    tbl_usuario.login,
    tbl_colaborador.nome AS colaborador,
    tbl_nivel_acesso.nome AS nivel_acesso
FROM tbl_usuario
INNER JOIN tbl_colaborador
    ON tbl_usuario.id_colaborador = tbl_colaborador.id
INNER JOIN tbl_nivel_acesso
    ON tbl_usuario.id_nivel_acesso = tbl_nivel_acesso.id
ORDER BY tbl_usuario.id;


-- ================================================================
-- ISSO TESTA:
-- Registro de ações realizadas pelos usuários no sistema.
--
-- Exemplos:
-- LOGIN
-- CRIAR
-- APROVAR
-- ATUALIZAR
--
-- A entidade identifica qual parte do sistema foi afetada.
-- O identificador_registro identifica o registro afetado.
-- ================================================================

INSERT INTO tbl_auditoria
    (id_usuario, acao, entidade, identificador_registro, descricao, data_hora)
VALUES
    (1,
     'LOGIN',
     'tbl_usuario',
     1,
     'Usuário realizou login no sistema.',
     '2026-10-01 08:30:00');


INSERT INTO tbl_auditoria
    (id_usuario, acao, entidade, identificador_registro, descricao, data_hora)
VALUES
    (2,
     'CRIAR',
     'tbl_colaborador',
     2,
     'Usuário cadastrou um novo colaborador.',
     '2026-10-01 09:15:00');


INSERT INTO tbl_auditoria
    (id_usuario, acao, entidade, identificador_registro, descricao, data_hora)
VALUES
    (3,
     'APROVAR',
     'tbl_ferias',
     3,
     'Usuário aprovou uma solicitação de férias.',
     '2026-10-01 10:00:00');


INSERT INTO tbl_auditoria
    (id_usuario, acao, entidade, identificador_registro, descricao, data_hora)
VALUES
    (2,
     'CRIAR',
     'tbl_plano_acao',
     1,
     'Usuário criou um novo plano de ação.',
     '2026-10-01 11:30:00');


-- ================================================================
-- CONFERIR TUDO:
-- ================================================================

SELECT
    tbl_auditoria.id,
    tbl_auditoria.id_usuario,
    tbl_usuario.login,
    tbl_colaborador.nome AS colaborador,
    tbl_nivel_acesso.nome AS nivel_acesso,
    tbl_auditoria.acao,
    tbl_auditoria.entidade,
    tbl_auditoria.identificador_registro,
    tbl_auditoria.descricao,
    tbl_auditoria.data_hora
FROM tbl_auditoria
INNER JOIN tbl_usuario
    ON tbl_auditoria.id_usuario = tbl_usuario.id
INNER JOIN tbl_colaborador
    ON tbl_usuario.id_colaborador = tbl_colaborador.id
INNER JOIN tbl_nivel_acesso
    ON tbl_usuario.id_nivel_acesso = tbl_nivel_acesso.id
ORDER BY tbl_auditoria.id;


-- ================================================================
-- TESTE DE ERRO:
-- ================================================================

-- Isso NÃO deve permitir registrar uma auditoria
-- para um usuário que não existe.
-- Deve dar erro de FOREIGN KEY.

-- TIRE O COMENTARIO PRA TESTAR:

-- INSERT INTO tbl_auditoria
--     (id_usuario, acao, entidade, identificador_registro, descricao, data_hora)
-- VALUES
--     (999,
--      'LOGIN',
--      'tbl_usuario',
--      999,
--      'Tentativa de auditoria com usuário inexistente.',
--      '2026-10-01 12:00:00');


-- ================================================================
-- FIM tbl_auditoria
-- ================================================================
